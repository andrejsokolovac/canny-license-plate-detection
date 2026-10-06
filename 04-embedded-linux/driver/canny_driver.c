#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/io.h>
#include <linux/slab.h>
#include <linux/err.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/types.h>
#include <linux/string.h>
#include <linux/delay.h>
#include <linux/mutex.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Andrej Sokolovac");
MODULE_DESCRIPTION("Linux platform driver for Canny Edge AXI IP core");

#define CANNY_NUM_DEVICES   3

#define CANNY_MINOR_CTRL    0
#define CANNY_MINOR_INPUT   1
#define CANNY_MINOR_EDGE    2

#define CANNY_DEV_CTRL      "canny_ctrl"
#define CANNY_DEV_INPUT     "canny_input"
#define CANNY_DEV_EDGE      "canny_edge"

#define CANNY_IMG_WIDTH     128U
#define CANNY_IMG_HEIGHT    96U
#define CANNY_IMG_BYTES     (CANNY_IMG_WIDTH * CANNY_IMG_HEIGHT)
#define CANNY_IMG_WORDS     (CANNY_IMG_BYTES / 4U)

#define CANNY_INPUT_OFF     0x00000U
#define CANNY_EDGE_OFF      0x40000U

#define REG_ROWS            0x00U
#define REG_COLS            0x04U
#define REG_LOW_THRESH      0x08U
#define REG_HIGH_THRESH     0x0CU
#define REG_START           0x10U
#define REG_READY           0x14U

#define CANNY_CTRL_BUF_SIZE         64U
#define CANNY_READY_IDLE_TIMEOUT    5000
#define CANNY_READY_BUSY_TIMEOUT    5000
#define CANNY_READY_DONE_TIMEOUT    30000

struct canny_device {
    void __iomem *ctrl_base;
    void __iomem *mem_base;

    u32 rows;
    u32 cols;
    u32 low_threshold;
    u32 high_threshold;

    struct mutex lock;

    dev_t dev_id;
    struct cdev cdev;
    struct class *class;
    struct device *devices[CANNY_NUM_DEVICES];
};

static const struct of_device_id canny_of_match[] = {
    { .compatible = "xlnx,canny-axi-1.0" },
    { }
};

MODULE_DEVICE_TABLE(of, canny_of_match);

static inline void canny_reg_write(struct canny_device *canny,
                                   u32 offset,
                                   u32 value)
{
    iowrite32(value, (u8 __iomem *)canny->ctrl_base + offset);
}

static inline u32 canny_reg_read(struct canny_device *canny, u32 offset)
{
    return ioread32((u8 __iomem *)canny->ctrl_base + offset);
}

static int canny_wait_ready_value(struct canny_device *canny,
                                  u32 wanted_value,
                                  int timeout_ms)
{
    while (timeout_ms-- > 0) {
        u32 ready = canny_reg_read(canny, REG_READY) & 0x1U;

        if (ready == (wanted_value & 0x1U))
            return 0;

        msleep(1);
    }

    return -ETIMEDOUT;
}

static int canny_wait_done_handshake(struct canny_device *canny)
{
    int ret;

    ret = canny_wait_ready_value(canny, 0U,
                                 CANNY_READY_BUSY_TIMEOUT);
    if (ret)
        return ret;

    ret = canny_wait_ready_value(canny, 1U,
                                 CANNY_READY_DONE_TIMEOUT);
    if (ret)
        return ret;

    return 0;
}

static int canny_open(struct inode *inode, struct file *file)
{
    struct canny_device *canny;

    canny = container_of(inode->i_cdev, struct canny_device, cdev);
    file->private_data = canny;

    return 0;
}

static int canny_release(struct inode *inode, struct file *file)
{
    return 0;
}

static ssize_t canny_read_ctrl(struct canny_device *canny,
                               char __user *buf,
                               size_t count,
                               loff_t *ppos)
{
    char kbuf[CANNY_CTRL_BUF_SIZE];
    int len;
    u32 ready;
    u32 rows;
    u32 cols;
    u32 low_threshold;
    u32 high_threshold;

    mutex_lock(&canny->lock);

    ready = canny_reg_read(canny, REG_READY) & 0x1U;
    rows = canny->rows;
    cols = canny->cols;
    low_threshold = canny->low_threshold;
    high_threshold = canny->high_threshold;

    mutex_unlock(&canny->lock);

    len = scnprintf(kbuf, sizeof(kbuf),
                    "ready=%u rows=%u cols=%u low=%u high=%u\n",
                    ready, rows, cols, low_threshold, high_threshold);

    return simple_read_from_buffer(buf, count, ppos, kbuf, len);
}

static ssize_t canny_read_edge(struct canny_device *canny,
                               char __user *buf,
                               size_t count,
                               loff_t *ppos)
{
    u8 *pixels;
    ssize_t ret;
    u32 i;

    if (*ppos >= CANNY_IMG_BYTES)
        return 0;

    pixels = kmalloc(CANNY_IMG_BYTES, GFP_KERNEL);
    if (!pixels)
        return -ENOMEM;

    mutex_lock(&canny->lock);

    if ((canny_reg_read(canny, REG_READY) & 0x1U) == 0U) {
        mutex_unlock(&canny->lock);
        kfree(pixels);
        return -EBUSY;
    }

    for (i = 0; i < CANNY_IMG_WORDS; i++) {
        u32 word;

        word = ioread32((u8 __iomem *)canny->mem_base +
                        CANNY_EDGE_OFF + i * 4U);

        pixels[4U * i + 0U] = (u8)(word & 0xFFU);
        pixels[4U * i + 1U] = (u8)((word >> 8) & 0xFFU);
        pixels[4U * i + 2U] = (u8)((word >> 16) & 0xFFU);
        pixels[4U * i + 3U] = (u8)((word >> 24) & 0xFFU);
    }

    mutex_unlock(&canny->lock);

    ret = simple_read_from_buffer(buf, count, ppos,
                                  pixels, CANNY_IMG_BYTES);

    kfree(pixels);

    return ret;
}

static ssize_t canny_read(struct file *file,
                          char __user *buf,
                          size_t count,
                          loff_t *ppos)
{
    struct canny_device *canny = file->private_data;
    int minor;

    minor = iminor(file_inode(file));

    switch (minor) {
    case CANNY_MINOR_CTRL:
        return canny_read_ctrl(canny, buf, count, ppos);

    case CANNY_MINOR_EDGE:
        return canny_read_edge(canny, buf, count, ppos);

    case CANNY_MINOR_INPUT:
        return -EINVAL;

    default:
        return -ENODEV;
    }
}

static int canny_write_image(struct canny_device *canny,
                             const char __user *buf,
                             size_t count)
{
    u8 *pixels;
    u32 i;

    if (count != CANNY_IMG_BYTES)
        return -EINVAL;

    pixels = memdup_user(buf, count);
    if (IS_ERR(pixels))
        return PTR_ERR(pixels);

    mutex_lock(&canny->lock);

    for (i = 0; i < CANNY_IMG_WORDS; i++) {
        u32 p0;
        u32 p1;
        u32 p2;
        u32 p3;
        u32 word;

        p0 = (u32)pixels[4U * i + 0U] & 0xFFU;
        p1 = (u32)pixels[4U * i + 1U] & 0xFFU;
        p2 = (u32)pixels[4U * i + 2U] & 0xFFU;
        p3 = (u32)pixels[4U * i + 3U] & 0xFFU;

        word = p0 | (p1 << 8) | (p2 << 16) | (p3 << 24);

        iowrite32(word,
                  (u8 __iomem *)canny->mem_base +
                  CANNY_INPUT_OFF + i * 4U);
    }

    mutex_unlock(&canny->lock);

    kfree(pixels);

    return 0;
}

static int canny_start_ip(struct canny_device *canny)
{
    int ret;

    ret = canny_wait_ready_value(canny, 1U,
                                 CANNY_READY_IDLE_TIMEOUT);
    if (ret)
        return ret;

    canny_reg_write(canny, REG_START, 0U);

    canny_reg_write(canny, REG_ROWS, canny->rows);
    canny_reg_write(canny, REG_COLS, canny->cols);
    canny_reg_write(canny, REG_LOW_THRESH, canny->low_threshold);
    canny_reg_write(canny, REG_HIGH_THRESH, canny->high_threshold);

    canny_reg_write(canny, REG_START, 1U);
    canny_reg_write(canny, REG_START, 0U);

    ret = canny_wait_done_handshake(canny);
    if (ret)
        return ret;

    return 0;
}

static int canny_write_ctrl(struct canny_device *canny,
                            const char __user *buf,
                            size_t count)
{
    char kbuf[CANNY_CTRL_BUF_SIZE];
    u32 rows;
    u32 cols;
    u32 low_threshold;
    u32 high_threshold;
    int ret;

    if (count == 0 || count >= CANNY_CTRL_BUF_SIZE)
        return -EINVAL;

    if (copy_from_user(kbuf, buf, count))
        return -EFAULT;

    kbuf[count] = '\0';

    ret = sscanf(kbuf, "config %u %u %u %u",
                 &rows, &cols, &low_threshold, &high_threshold);

    if (ret == 4) {
        if (rows != CANNY_IMG_HEIGHT ||
            cols != CANNY_IMG_WIDTH)
            return -EINVAL;

        if (low_threshold > 0xFFU ||
            high_threshold > 0xFFU ||
            low_threshold > high_threshold)
            return -EINVAL;

        mutex_lock(&canny->lock);

        canny->rows = rows;
        canny->cols = cols;
        canny->low_threshold = low_threshold;
        canny->high_threshold = high_threshold;

        canny_reg_write(canny, REG_ROWS, rows);
        canny_reg_write(canny, REG_COLS, cols);
        canny_reg_write(canny, REG_LOW_THRESH, low_threshold);
        canny_reg_write(canny, REG_HIGH_THRESH, high_threshold);

        mutex_unlock(&canny->lock);

        pr_info("Canny driver: config rows=%u cols=%u low=%u high=%u\n",
                rows, cols, low_threshold, high_threshold);

        return 0;
    }

    if (sysfs_streq(kbuf, "start")) {
        mutex_lock(&canny->lock);

        ret = canny_start_ip(canny);

        mutex_unlock(&canny->lock);

        if (ret) {
            pr_err("Canny driver: READY handshake timeout\n");
            return ret;
        }

        pr_info("Canny driver: IP finished\n");
        return 0;
    }

    return -EINVAL;
}

static ssize_t canny_write(struct file *file,
                           const char __user *buf,
                           size_t count,
                           loff_t *ppos)
{
    struct canny_device *canny = file->private_data;
    int minor;
    int ret;

    minor = iminor(file_inode(file));

    switch (minor) {
    case CANNY_MINOR_INPUT:
        ret = canny_write_image(canny, buf, count);
        if (ret)
            return ret;

        pr_info("Canny driver: input image received (%zu bytes)\n",
                count);
        return count;

    case CANNY_MINOR_CTRL:
        ret = canny_write_ctrl(canny, buf, count);
        if (ret)
            return ret;

        return count;

    case CANNY_MINOR_EDGE:
        return -EINVAL;

    default:
        return -ENODEV;
    }
}

static const struct file_operations canny_fops = {
    .owner = THIS_MODULE,
    .open = canny_open,
    .release = canny_release,
    .read = canny_read,
    .write = canny_write,
};

static int canny_create_char_devices(struct platform_device *pdev,
                                     struct canny_device *canny)
{
    int ret;
    int i;
    const char *names[CANNY_NUM_DEVICES] = {
        CANNY_DEV_CTRL,
        CANNY_DEV_INPUT,
        CANNY_DEV_EDGE
    };

    ret = alloc_chrdev_region(&canny->dev_id, 0,
                              CANNY_NUM_DEVICES, "canny");
    if (ret) {
        dev_err(&pdev->dev,
                "Failed to allocate char device numbers\n");
        return ret;
    }

    cdev_init(&canny->cdev, &canny_fops);
    canny->cdev.owner = THIS_MODULE;

    ret = cdev_add(&canny->cdev, canny->dev_id,
                   CANNY_NUM_DEVICES);
    if (ret) {
        dev_err(&pdev->dev, "Failed to add cdev\n");
        unregister_chrdev_region(canny->dev_id,
                                 CANNY_NUM_DEVICES);
        return ret;
    }

    canny->class = class_create(THIS_MODULE, "canny_class");
    if (IS_ERR(canny->class)) {
        ret = PTR_ERR(canny->class);
        dev_err(&pdev->dev, "Failed to create class\n");
        cdev_del(&canny->cdev);
        unregister_chrdev_region(canny->dev_id,
                                 CANNY_NUM_DEVICES);
        return ret;
    }

    for (i = 0; i < CANNY_NUM_DEVICES; i++) {
        canny->devices[i] = device_create(
            canny->class,
            NULL,
            MKDEV(MAJOR(canny->dev_id), i),
            NULL,
            "%s",
            names[i]);

        if (IS_ERR(canny->devices[i])) {
            ret = PTR_ERR(canny->devices[i]);
            dev_err(&pdev->dev,
                    "Failed to create /dev/%s\n",
                    names[i]);

            while (--i >= 0)
                device_destroy(canny->class,
                               MKDEV(MAJOR(canny->dev_id), i));

            class_destroy(canny->class);
            cdev_del(&canny->cdev);
            unregister_chrdev_region(canny->dev_id,
                                     CANNY_NUM_DEVICES);
            return ret;
        }
    }

    dev_info(&pdev->dev,
             "Created /dev/%s, /dev/%s, /dev/%s\n",
             CANNY_DEV_CTRL,
             CANNY_DEV_INPUT,
             CANNY_DEV_EDGE);

    return 0;
}

static void canny_destroy_char_devices(struct canny_device *canny)
{
    int i;

    for (i = 0; i < CANNY_NUM_DEVICES; i++)
        device_destroy(canny->class,
                       MKDEV(MAJOR(canny->dev_id), i));

    class_destroy(canny->class);
    cdev_del(&canny->cdev);
    unregister_chrdev_region(canny->dev_id,
                             CANNY_NUM_DEVICES);
}

static int canny_probe(struct platform_device *pdev)
{
    struct canny_device *canny;
    struct resource *ctrl_res;
    struct resource *mem_res;
    resource_size_t mem_size;
    int ret;

    canny = devm_kzalloc(&pdev->dev, sizeof(*canny), GFP_KERNEL);
    if (!canny)
        return -ENOMEM;

    mutex_init(&canny->lock);

    canny->rows = CANNY_IMG_HEIGHT;
    canny->cols = CANNY_IMG_WIDTH;
    canny->low_threshold = 50U;
    canny->high_threshold = 100U;

    ctrl_res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!ctrl_res) {
        dev_err(&pdev->dev,
                "Failed to get AXI-Lite resource\n");
        return -ENODEV;
    }

    canny->ctrl_base = devm_ioremap_resource(&pdev->dev,
                                              ctrl_res);
    if (IS_ERR(canny->ctrl_base)) {
        dev_err(&pdev->dev,
                "Failed to map AXI-Lite registers\n");
        return PTR_ERR(canny->ctrl_base);
    }

    mem_res = platform_get_resource(pdev, IORESOURCE_MEM, 1);
    if (!mem_res) {
        dev_err(&pdev->dev,
                "Failed to get AXI-Full memory resource\n");
        return -ENODEV;
    }

    mem_size = resource_size(mem_res);
    if (mem_size < CANNY_EDGE_OFF + CANNY_IMG_BYTES) {
        dev_err(&pdev->dev,
                "AXI-Full resource is too small: size=0x%llx\n",
                (unsigned long long)mem_size);
        return -EINVAL;
    }

    canny->mem_base = devm_ioremap_resource(&pdev->dev,
                                             mem_res);
    if (IS_ERR(canny->mem_base)) {
        dev_err(&pdev->dev,
                "Failed to map AXI-Full memory space\n");
        return PTR_ERR(canny->mem_base);
    }

    ret = canny_create_char_devices(pdev, canny);
    if (ret)
        return ret;

    platform_set_drvdata(pdev, canny);

    dev_info(&pdev->dev, "Canny AXI IP matched\n");
    dev_info(&pdev->dev,
             "AXI-Lite mapped: start=%pa size=0x%lx\n",
             &ctrl_res->start,
             (unsigned long)resource_size(ctrl_res));
    dev_info(&pdev->dev,
             "AXI-Full mapped: start=%pa size=0x%lx\n",
             &mem_res->start,
             (unsigned long)resource_size(mem_res));

    return 0;
}

static int canny_remove(struct platform_device *pdev)
{
    struct canny_device *canny = platform_get_drvdata(pdev);

    canny_destroy_char_devices(canny);

    dev_info(&pdev->dev, "Canny driver removed\n");

    return 0;
}

static struct platform_driver canny_platform_driver = {
    .probe = canny_probe,
    .remove = canny_remove,
    .driver = {
        .name = "canny_driver",
        .of_match_table = canny_of_match,
    },
};

module_platform_driver(canny_platform_driver);

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ip is
    generic (
        IMG_WIDTH  : integer := 512;
        IMG_HEIGHT : integer := 384;
        ADDR_WIDTH : integer := 18
    );
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        start : in  std_logic;
        ready : out std_logic;

        rows  : in  std_logic_vector(8 downto 0);
        cols  : in  std_logic_vector(9 downto 0);
        
        low_threshold_i  : in std_logic_vector(7 downto 0);
        high_threshold_i : in std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- INPUT BRAM (grayscale image)
        ----------------------------------------------------------------
        input_ena   : out std_logic;
        input_wea   : out std_logic;
        input_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        input_dia   : out std_logic_vector(7 downto 0);
        input_doa   : in  std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- GAUSS BRAM
        ----------------------------------------------------------------
        gauss_ena   : out std_logic;
        gauss_wea   : out std_logic;
        gauss_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        gauss_dia   : out std_logic_vector(7 downto 0);
        gauss_doa   : in  std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- MAG BRAM
        ----------------------------------------------------------------
        mag_ena   : out std_logic;
        mag_wea   : out std_logic;
        mag_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        mag_dia   : out std_logic_vector(15 downto 0);
        mag_doa   : in  std_logic_vector(15 downto 0);

        ----------------------------------------------------------------
        -- DIR BRAM
        ----------------------------------------------------------------
        dir_ena   : out std_logic;
        dir_wea   : out std_logic;
        dir_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        dir_dia   : out std_logic_vector(7 downto 0);
        dir_doa   : in  std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- NMS BRAM
        ----------------------------------------------------------------
        nms_ena   : out std_logic;
        nms_wea   : out std_logic;
        nms_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        nms_dia   : out std_logic_vector(15 downto 0);
        nms_doa   : in  std_logic_vector(15 downto 0);

        ----------------------------------------------------------------
        -- THRESH BRAM
        ----------------------------------------------------------------
        thresh_ena   : out std_logic;
        thresh_wea   : out std_logic;
        thresh_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        thresh_dia   : out std_logic_vector(7 downto 0);
        thresh_doa   : in  std_logic_vector(7 downto 0);

        ----------------------------------------------------------------
        -- EDGE BRAM
        ----------------------------------------------------------------
        edge_ena   : out std_logic;
        edge_wea   : out std_logic;
        edge_addra : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        edge_dia   : out std_logic_vector(7 downto 0);
        edge_doa   : in  std_logic_vector(7 downto 0)
    );
end ip;

architecture Behavioral of ip is

    type state_type is (
        IDLE,
        LOAD_IMAGE,
        PROCESS_ROWS,

        ----------------------------------------------------------------
        -- GAUSS
        ----------------------------------------------------------------
        INIT_GAUSS,
        GAUSS_INIT_SUM,
        GAUSS_INIT_KERNEL,
        GAUSS_READ_PIXEL,
        GAUSS_WAIT_READ,
        GAUSS_LATCH_PIXEL,
        GAUSS_MUL_ACC,
        GAUSS_NEXT_KERNEL,
        GAUSS_NORMALIZE,
        GAUSS_WRITE,
        GAUSS_NEXT_PIXEL,
        GAUSS_DONE,

        ----------------------------------------------------------------
        -- SOBEL (gx/gy + magnitude + direction)
        ----------------------------------------------------------------
        INIT_SOBEL,
        SOBEL_RESET_GXGY,
        SOBEL_INIT_KERNEL,
        SOBEL_READ_PIXEL,
        SOBEL_WAIT_READ,
        SOBEL_LATCH_PIXEL,
        SOBEL_ACC_GXGY,
        SOBEL_NEXT_KERNEL,
        SOBEL_DONE_KERNEL,
        SOBEL_CALC_SQUARE,
        SOBEL_ISQRT_INIT,
        SOBEL_ISQRT_ALIGN,
        SOBEL_ISQRT_ITER,
        SOBEL_ISQRT_DONE,
        SOBEL_WRITE_MAG,
        SOBEL_ABS,
        SOBEL_DIR_DECIDE,
        SOBEL_WRITE_DIR,
        SOBEL_NEXT_PIXEL,

        ----------------------------------------------------------------
        -- NMS
        ----------------------------------------------------------------
        INIT_NMS,
        NMS_READ_CENTER_MAG,
        NMS_WAIT_CENTER_MAG,
        NMS_LATCH_CENTER_MAG,
        NMS_READ_DIR,
        NMS_WAIT_DIR,
        NMS_LATCH_DIR,
        NMS_SET_NEIGH_ADDRS,
        NMS_READ_Q,
        NMS_WAIT_Q,
        NMS_LATCH_Q,
        NMS_READ_R,
        NMS_WAIT_R,
        NMS_LATCH_R,
        NMS_COMPARE,
        NMS_WRITE,
        NMS_NEXT_PIXEL,
        NMS_DONE,

        ----------------------------------------------------------------
        -- THRESH
        ----------------------------------------------------------------
        INIT_THRESH,
        THRESH_READ,
        THRESH_WAIT,
        THRESH_LATCH,
        THRESH_CLASSIFY,
        THRESH_WRITE,
        THRESH_NEXT_PIXEL,
        THRESH_DONE,

        ----------------------------------------------------------------
        -- EDGE COPY
        ----------------------------------------------------------------
        INIT_EDGE_COPY,
        EDGE_COPY_READ,
        EDGE_COPY_WAIT,
        EDGE_COPY_LATCH,
        EDGE_COPY_WRITE,
        EDGE_COPY_NEXT_PIXEL,
        EDGE_COPY_DONE,

        ----------------------------------------------------------------
        -- HYST
        ----------------------------------------------------------------
        INIT_HYST,
        HYST_READ_CENTER,
        HYST_WAIT_CENTER,
        HYST_LATCH_CENTER,
        HYST_INIT_NEIGH,
        HYST_READ_NEIGH,
        HYST_WAIT_NEIGH,
        HYST_LATCH_NEIGH,
        HYST_CHECK_NEIGH,
        HYST_NEXT_NEIGH,
        HYST_WRITE,
        HYST_NEXT_PIXEL,
        HYST_DONE,

        DONE
    );

    signal state : state_type := IDLE;
    signal ready_reg : std_logic := '1';

    signal reg_rows : unsigned(8 downto 0) := (others => '0');
    signal reg_cols : unsigned(9 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- GAUSS registri
    --------------------------------------------------------------------
    signal reg_i : unsigned(8 downto 0) := (others => '0');
    signal reg_j : unsigned(9 downto 0) := (others => '0');

    signal reg_k : integer range -2 to 2 := -2;
    signal reg_l : integer range -2 to 2 := -2;

    signal reg_addr      : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal reg_input_pix : unsigned(7 downto 0) := (others => '0');

    signal reg_sum       : unsigned(15 downto 0) := (others => '0');
    signal reg_gauss_pix : unsigned(7 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- SOBEL registri
    --------------------------------------------------------------------
    signal reg_sobel_i : unsigned(8 downto 0) := (others => '0');
    signal reg_sobel_j : unsigned(9 downto 0) := (others => '0');

    signal reg_sobel_k : integer range -1 to 1 := -1;
    signal reg_sobel_l : integer range -1 to 1 := -1;

    signal reg_sobel_pix : unsigned(7 downto 0) := (others => '0');

    signal reg_gx : integer range -32768 to 32767 := 0;
    signal reg_gy : integer range -32768 to 32767 := 0;

    --------------------------------------------------------------------
    -- Magnitude / isqrt registri
    --------------------------------------------------------------------
    signal reg_grad_sq   : unsigned(31 downto 0) := (others => '0');
    signal reg_isqrt_num : unsigned(31 downto 0) := (others => '0');
    signal reg_isqrt_res : unsigned(31 downto 0) := (others => '0');
    signal reg_isqrt_bit : unsigned(31 downto 0) := (others => '0');
    signal reg_mag       : unsigned(15 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- Direction registri
    --------------------------------------------------------------------
    signal reg_abs_gx  : unsigned(15 downto 0) := (others => '0');
    signal reg_abs_gy  : unsigned(15 downto 0) := (others => '0');
    signal reg_dir_val : unsigned(7 downto 0)  := (others => '0');

    --------------------------------------------------------------------
    -- NMS registri
    --------------------------------------------------------------------
    signal reg_nms_i   : unsigned(8 downto 0) := (others => '0');
    signal reg_nms_j   : unsigned(9 downto 0) := (others => '0');

    signal reg_nms_mag : unsigned(15 downto 0) := (others => '0');
    signal reg_nms_dir : unsigned(7 downto 0)  := (others => '0');

    signal reg_q_mag   : unsigned(15 downto 0) := (others => '0');
    signal reg_r_mag   : unsigned(15 downto 0) := (others => '0');

    signal reg_nms_out : unsigned(15 downto 0) := (others => '0');

    signal reg_q_addr  : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal reg_r_addr  : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- THRESH registri
    --------------------------------------------------------------------
    signal reg_thresh_i   : unsigned(8 downto 0) := (others => '0');
    signal reg_thresh_j   : unsigned(9 downto 0) := (others => '0');
    signal reg_thresh_pix : unsigned(15 downto 0) := (others => '0');
    signal reg_thresh_out : unsigned(7 downto 0)  := (others => '0');

    --constant LOW_THRESHOLD  : integer := 50;
    --constant HIGH_THRESHOLD : integer := 100;
    constant WEAK_EDGE      : integer := 127;
    constant STRONG_EDGE    : integer := 255;

    --------------------------------------------------------------------
    -- EDGE COPY registri
    --------------------------------------------------------------------
    signal reg_copy_i   : unsigned(8 downto 0) := (others => '0');
    signal reg_copy_j   : unsigned(9 downto 0) := (others => '0');
    signal reg_copy_pix : unsigned(7 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- HYST registri
    --------------------------------------------------------------------
    signal reg_hyst_i         : unsigned(8 downto 0) := (others => '0');
    signal reg_hyst_j         : unsigned(9 downto 0) := (others => '0');
    signal reg_hyst_pix       : unsigned(7 downto 0) := (others => '0');
    signal reg_hyst_out       : unsigned(7 downto 0) := (others => '0');
    signal reg_hyst_neigh     : unsigned(7 downto 0) := (others => '0');
    signal reg_hyst_k         : integer range -1 to 1 := -1;
    signal reg_hyst_l         : integer range -1 to 1 := -1;
    signal reg_hyst_connected : std_logic := '0';
    signal reg_hyst_addr      : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- Kerneli
    --------------------------------------------------------------------
    type kernel_type is array (0 to 4, 0 to 4) of integer;
    constant gauss_kernel : kernel_type := (
        (1,  4,  6,  4, 1),
        (4, 16, 24, 16, 4),
        (6, 24, 36, 24, 6),
        (4, 16, 24, 16, 4),
        (1,  4,  6,  4, 1)
    );

    type sobel_kernel_type is array (0 to 2, 0 to 2) of integer;

    constant sobel_x_kernel : sobel_kernel_type := (
        (-1,  0,  1),
        (-2,  0,  2),
        (-1,  0,  1)
    );

    constant sobel_y_kernel : sobel_kernel_type := (
        ( 1,  2,  1),
        ( 0,  0,  0),
        (-1, -2, -1)
    );

begin

    ready <= ready_reg;

    --------------------------------------------------------------------
    -- BRAM kontrole
    --------------------------------------------------------------------

    input_ena <= '1' when (
        state = GAUSS_READ_PIXEL or
        state = GAUSS_WAIT_READ or
        state = GAUSS_LATCH_PIXEL
    ) else '0';

    input_wea   <= '0';
    input_addra <= std_logic_vector(reg_addr);
    input_dia   <= (others => '0');

    gauss_ena <= '1' when (
        state = GAUSS_WRITE or
        state = SOBEL_READ_PIXEL or
        state = SOBEL_WAIT_READ or
        state = SOBEL_LATCH_PIXEL
    ) else '0';

    gauss_wea <= '1' when (state = GAUSS_WRITE) else '0';

    gauss_addra <= std_logic_vector(reg_addr)
                   when (state = SOBEL_READ_PIXEL or state = SOBEL_WAIT_READ or state = SOBEL_LATCH_PIXEL)
                   else std_logic_vector(resize(reg_i * reg_cols + reg_j, ADDR_WIDTH));

    gauss_dia <= std_logic_vector(reg_gauss_pix);

    mag_ena <= '1' when (
        state = SOBEL_WRITE_MAG or
        state = NMS_READ_CENTER_MAG or
        state = NMS_WAIT_CENTER_MAG or
        state = NMS_LATCH_CENTER_MAG or
        state = NMS_READ_Q or
        state = NMS_WAIT_Q or
        state = NMS_LATCH_Q or
        state = NMS_READ_R or
        state = NMS_WAIT_R or
        state = NMS_LATCH_R
    ) else '0';

    mag_wea <= '1' when (state = SOBEL_WRITE_MAG) else '0';

    mag_addra <= std_logic_vector(resize(reg_sobel_i * reg_cols + reg_sobel_j, ADDR_WIDTH))
                 when (state = SOBEL_WRITE_MAG) else
                 std_logic_vector(resize(reg_nms_i * reg_cols + reg_nms_j, ADDR_WIDTH))
                 when (state = NMS_READ_CENTER_MAG or state = NMS_WAIT_CENTER_MAG or state = NMS_LATCH_CENTER_MAG) else
                 std_logic_vector(reg_q_addr)
                 when (state = NMS_READ_Q or state = NMS_WAIT_Q or state = NMS_LATCH_Q) else
                 std_logic_vector(reg_r_addr)
                 when (state = NMS_READ_R or state = NMS_WAIT_R or state = NMS_LATCH_R) else
                 (others => '0');

    mag_dia <= std_logic_vector(reg_mag);

    dir_ena <= '1' when (
        state = SOBEL_WRITE_DIR or
        state = NMS_READ_DIR or
        state = NMS_WAIT_DIR or
        state = NMS_LATCH_DIR
    ) else '0';

    dir_wea <= '1' when (state = SOBEL_WRITE_DIR) else '0';

    dir_addra <= std_logic_vector(resize(reg_sobel_i * reg_cols + reg_sobel_j, ADDR_WIDTH))
                 when (state = SOBEL_WRITE_DIR) else
                 std_logic_vector(resize(reg_nms_i * reg_cols + reg_nms_j, ADDR_WIDTH))
                 when (state = NMS_READ_DIR or state = NMS_WAIT_DIR or state = NMS_LATCH_DIR) else
                 (others => '0');

    dir_dia <= std_logic_vector(reg_dir_val);

    nms_ena <= '1' when (
        state = NMS_WRITE or
        state = THRESH_READ or
        state = THRESH_WAIT or
        state = THRESH_LATCH
    ) else '0';

    nms_wea <= '1' when (state = NMS_WRITE) else '0';

    nms_addra <= std_logic_vector(resize(reg_nms_i * reg_cols + reg_nms_j, ADDR_WIDTH))
                 when (state = NMS_WRITE) else
                 std_logic_vector(resize(reg_thresh_i * reg_cols + reg_thresh_j, ADDR_WIDTH))
                 when (state = THRESH_READ or state = THRESH_WAIT or state = THRESH_LATCH) else
                 (others => '0');

    nms_dia <= std_logic_vector(reg_nms_out);

    thresh_ena <= '1' when (
        state = THRESH_WRITE or
        state = EDGE_COPY_READ or
        state = EDGE_COPY_WAIT or
        state = EDGE_COPY_LATCH
    ) else '0';

    thresh_wea <= '1' when (state = THRESH_WRITE) else '0';

    thresh_addra <= std_logic_vector(resize(reg_thresh_i * reg_cols + reg_thresh_j, ADDR_WIDTH))
                    when (state = THRESH_WRITE) else
                    std_logic_vector(resize(reg_copy_i * reg_cols + reg_copy_j, ADDR_WIDTH))
                    when (state = EDGE_COPY_READ or state = EDGE_COPY_WAIT or state = EDGE_COPY_LATCH) else
                    (others => '0');

    thresh_dia <= std_logic_vector(reg_thresh_out);

    edge_ena <= '1' when (
        state = EDGE_COPY_WRITE or
        state = HYST_READ_CENTER or
        state = HYST_WAIT_CENTER or
        state = HYST_LATCH_CENTER or
        state = HYST_READ_NEIGH or
        state = HYST_WAIT_NEIGH or
        state = HYST_LATCH_NEIGH or
        state = HYST_WRITE
    ) else '0';

    edge_wea <= '1' when (
        state = EDGE_COPY_WRITE or
        state = HYST_WRITE
    ) else '0';

    edge_addra <= std_logic_vector(resize(reg_copy_i * reg_cols + reg_copy_j, ADDR_WIDTH))
                  when (state = EDGE_COPY_WRITE) else
                  std_logic_vector(resize(reg_hyst_i * reg_cols + reg_hyst_j, ADDR_WIDTH))
                  when (state = HYST_WRITE) else
                  std_logic_vector(reg_hyst_addr)
                  when (state = HYST_READ_CENTER or state = HYST_WAIT_CENTER or state = HYST_LATCH_CENTER or
                        state = HYST_READ_NEIGH  or state = HYST_WAIT_NEIGH  or state = HYST_LATCH_NEIGH) else
                  (others => '0');

    edge_dia <= std_logic_vector(reg_copy_pix)
                when (state = EDGE_COPY_WRITE) else
                std_logic_vector(reg_hyst_out)
                when (state = HYST_WRITE) else
                (others => '0');

    --------------------------------------------------------------------
    -- Single-process FSM
    --------------------------------------------------------------------
    process(clk)
        variable temp_addr   : unsigned(ADDR_WIDTH-1 downto 0);
        variable pixel_row   : integer;
        variable pixel_col   : integer;
        variable kernel_val  : integer;
        variable mult_val    : integer;
        variable sum_int     : integer;
        variable candidate   : unsigned(31 downto 0);
        variable q_addr_int  : integer;
        variable r_addr_int  : integer;
        variable hyst_addr_i : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state         <= IDLE;
                ready_reg     <= '1';

                reg_rows      <= (others => '0');
                reg_cols      <= (others => '0');

                reg_i         <= (others => '0');
                reg_j         <= (others => '0');
                reg_k         <= -2;
                reg_l         <= -2;

                reg_addr      <= (others => '0');
                reg_input_pix <= (others => '0');

                reg_sum       <= (others => '0');
                reg_gauss_pix <= (others => '0');

                reg_sobel_i   <= (others => '0');
                reg_sobel_j   <= (others => '0');
                reg_sobel_k   <= -1;
                reg_sobel_l   <= -1;
                reg_sobel_pix <= (others => '0');

                reg_gx        <= 0;
                reg_gy        <= 0;

                reg_grad_sq   <= (others => '0');
                reg_isqrt_num <= (others => '0');
                reg_isqrt_res <= (others => '0');
                reg_isqrt_bit <= (others => '0');
                reg_mag       <= (others => '0');

                reg_abs_gx    <= (others => '0');
                reg_abs_gy    <= (others => '0');
                reg_dir_val   <= (others => '0');

                reg_nms_i     <= (others => '0');
                reg_nms_j     <= (others => '0');
                reg_nms_mag   <= (others => '0');
                reg_nms_dir   <= (others => '0');
                reg_q_mag     <= (others => '0');
                reg_r_mag     <= (others => '0');
                reg_nms_out   <= (others => '0');
                reg_q_addr    <= (others => '0');
                reg_r_addr    <= (others => '0');

                reg_thresh_i   <= (others => '0');
                reg_thresh_j   <= (others => '0');
                reg_thresh_pix <= (others => '0');
                reg_thresh_out <= (others => '0');

                reg_copy_i   <= (others => '0');
                reg_copy_j   <= (others => '0');
                reg_copy_pix <= (others => '0');

                reg_hyst_i         <= (others => '0');
                reg_hyst_j         <= (others => '0');
                reg_hyst_pix       <= (others => '0');
                reg_hyst_out       <= (others => '0');
                reg_hyst_neigh     <= (others => '0');
                reg_hyst_k         <= -1;
                reg_hyst_l         <= -1;
                reg_hyst_connected <= '0';
                reg_hyst_addr      <= (others => '0');

            else
                case state is

                    when IDLE =>
                        ready_reg <= '1';
                        if start = '1' then
                            reg_rows  <= unsigned(rows);
                            reg_cols  <= unsigned(cols);
                            ready_reg <= '0';
                            state     <= LOAD_IMAGE;
                        else
                            state <= IDLE;
                        end if;

                    when LOAD_IMAGE =>
                        reg_i <= to_unsigned(2, reg_i'length);
                        reg_j <= to_unsigned(2, reg_j'length);
                        state <= PROCESS_ROWS;

                    when PROCESS_ROWS =>
                        state <= INIT_GAUSS;

                    ----------------------------------------------------------------
                    -- GAUSS
                    ----------------------------------------------------------------
                    when INIT_GAUSS =>
                        reg_sum <= (others => '0');
                        state   <= GAUSS_INIT_SUM;

                    when GAUSS_INIT_SUM =>
                        reg_sum <= (others => '0');
                        state   <= GAUSS_INIT_KERNEL;

                    when GAUSS_INIT_KERNEL =>
                        reg_k   <= -2;
                        reg_l   <= -2;
                        state   <= GAUSS_READ_PIXEL;

                    when GAUSS_READ_PIXEL =>
                        pixel_row := to_integer(reg_i) + reg_k;
                        pixel_col := to_integer(reg_j) + reg_l;
                        temp_addr := to_unsigned(pixel_row * to_integer(reg_cols) + pixel_col, ADDR_WIDTH);
                        reg_addr  <= temp_addr;
                        state     <= GAUSS_WAIT_READ;

                    when GAUSS_WAIT_READ =>
                        state <= GAUSS_LATCH_PIXEL;

                    when GAUSS_LATCH_PIXEL =>
                        reg_input_pix <= unsigned(input_doa);
                        state         <= GAUSS_MUL_ACC;

                    when GAUSS_MUL_ACC =>
                        kernel_val := gauss_kernel(reg_k + 2, reg_l + 2);
                        mult_val   := to_integer(reg_input_pix) * kernel_val;
                        sum_int    := to_integer(reg_sum) + mult_val;
                        reg_sum    <= to_unsigned(sum_int, reg_sum'length);
                        state      <= GAUSS_NEXT_KERNEL;

                    when GAUSS_NEXT_KERNEL =>
                        if (reg_k = 2) and (reg_l = 2) then
                            state <= GAUSS_NORMALIZE;
                        elsif reg_l < 2 then
                            reg_l <= reg_l + 1;
                            state <= GAUSS_READ_PIXEL;
                        else
                            reg_l <= -2;
                            reg_k <= reg_k + 1;
                            state <= GAUSS_READ_PIXEL;
                        end if;

                    when GAUSS_NORMALIZE =>
                        reg_gauss_pix <= resize(reg_sum / 256, reg_gauss_pix'length);
                        state         <= GAUSS_WRITE;

                    when GAUSS_WRITE =>
                        state <= GAUSS_NEXT_PIXEL;

                    when GAUSS_NEXT_PIXEL =>
                        if (reg_i = reg_rows - 3) and (reg_j = reg_cols - 3) then
                            state <= GAUSS_DONE;
                        elsif reg_j < reg_cols - 3 then
                            reg_j <= reg_j + 1;
                            state <= INIT_GAUSS;
                        else
                            reg_j <= to_unsigned(2, reg_j'length);
                            reg_i <= reg_i + 1;
                            state <= INIT_GAUSS;
                        end if;

                    when GAUSS_DONE =>
                        reg_sobel_i <= to_unsigned(3, reg_sobel_i'length);
                        reg_sobel_j <= to_unsigned(3, reg_sobel_j'length);
                        state       <= INIT_SOBEL;

                    ----------------------------------------------------------------
                    -- SOBEL
                    ----------------------------------------------------------------
                    when INIT_SOBEL =>
                        state <= SOBEL_RESET_GXGY;

                    when SOBEL_RESET_GXGY =>
                        reg_gx <= 0;
                        reg_gy <= 0;
                        state  <= SOBEL_INIT_KERNEL;

                    when SOBEL_INIT_KERNEL =>
                        reg_sobel_k <= -1;
                        reg_sobel_l <= -1;
                        state       <= SOBEL_READ_PIXEL;

                    when SOBEL_READ_PIXEL =>
                        pixel_row := to_integer(reg_sobel_i) + reg_sobel_k;
                        pixel_col := to_integer(reg_sobel_j) + reg_sobel_l;
                        temp_addr := to_unsigned(pixel_row * to_integer(reg_cols) + pixel_col, ADDR_WIDTH);
                        reg_addr  <= temp_addr;
                        state     <= SOBEL_WAIT_READ;

                    when SOBEL_WAIT_READ =>
                        state <= SOBEL_LATCH_PIXEL;

                    when SOBEL_LATCH_PIXEL =>
                        reg_sobel_pix <= unsigned(gauss_doa);
                        state         <= SOBEL_ACC_GXGY;

                    when SOBEL_ACC_GXGY =>
                        reg_gx <= reg_gx + sobel_x_kernel(reg_sobel_k + 1, reg_sobel_l + 1) * to_integer(reg_sobel_pix);
                        reg_gy <= reg_gy + sobel_y_kernel(reg_sobel_k + 1, reg_sobel_l + 1) * to_integer(reg_sobel_pix);
                        state  <= SOBEL_NEXT_KERNEL;

                    when SOBEL_NEXT_KERNEL =>
                        if (reg_sobel_k = 1) and (reg_sobel_l = 1) then
                            state <= SOBEL_DONE_KERNEL;
                        elsif reg_sobel_l < 1 then
                            reg_sobel_l <= reg_sobel_l + 1;
                            state <= SOBEL_READ_PIXEL;
                        else
                            reg_sobel_l <= -1;
                            reg_sobel_k <= reg_sobel_k + 1;
                            state <= SOBEL_READ_PIXEL;
                        end if;

                    when SOBEL_DONE_KERNEL =>
                        state <= SOBEL_CALC_SQUARE;

                    when SOBEL_CALC_SQUARE =>
                        reg_grad_sq   <= to_unsigned((reg_gx * reg_gx) + (reg_gy * reg_gy), 32);
                        reg_isqrt_num <= to_unsigned((reg_gx * reg_gx) + (reg_gy * reg_gy), 32);
                        state         <= SOBEL_ISQRT_INIT;

                    when SOBEL_ISQRT_INIT =>
                        reg_isqrt_res <= (others => '0');
                        reg_isqrt_bit <= x"40000000";
                        state         <= SOBEL_ISQRT_ALIGN;

                    when SOBEL_ISQRT_ALIGN =>
                        if reg_isqrt_bit > reg_isqrt_num then
                            reg_isqrt_bit <= shift_right(reg_isqrt_bit, 2);
                            state         <= SOBEL_ISQRT_ALIGN;
                        else
                            state <= SOBEL_ISQRT_ITER;
                        end if;

                    when SOBEL_ISQRT_ITER =>
                        if reg_isqrt_bit = 0 then
                            state <= SOBEL_ISQRT_DONE;
                        else
                            candidate := reg_isqrt_res + reg_isqrt_bit;
                            if reg_isqrt_num >= candidate then
                                reg_isqrt_num <= reg_isqrt_num - candidate;
                                reg_isqrt_res <= shift_right(reg_isqrt_res, 1) + reg_isqrt_bit;
                            else
                                reg_isqrt_res <= shift_right(reg_isqrt_res, 1);
                            end if;
                            reg_isqrt_bit <= shift_right(reg_isqrt_bit, 2);
                            state         <= SOBEL_ISQRT_ITER;
                        end if;

                    when SOBEL_ISQRT_DONE =>
                        reg_mag <= reg_isqrt_res(15 downto 0);
                        state   <= SOBEL_WRITE_MAG;

                    when SOBEL_WRITE_MAG =>
                        state <= SOBEL_ABS;

                    when SOBEL_ABS =>
                        if reg_gx < 0 then
                            reg_abs_gx <= to_unsigned(-reg_gx, reg_abs_gx'length);
                        else
                            reg_abs_gx <= to_unsigned(reg_gx, reg_abs_gx'length);
                        end if;

                        if reg_gy < 0 then
                            reg_abs_gy <= to_unsigned(-reg_gy, reg_abs_gy'length);
                        else
                            reg_abs_gy <= to_unsigned(reg_gy, reg_abs_gy'length);
                        end if;

                        state <= SOBEL_DIR_DECIDE;

                    when SOBEL_DIR_DECIDE =>
                        if reg_abs_gx > reg_abs_gy then
                            reg_dir_val <= to_unsigned(0, reg_dir_val'length);
                        elsif reg_abs_gy > reg_abs_gx then
                            reg_dir_val <= to_unsigned(90, reg_dir_val'length);
                        else
                            if ((reg_gx > 0 and reg_gy > 0) or (reg_gx < 0 and reg_gy < 0)) then
                                reg_dir_val <= to_unsigned(45, reg_dir_val'length);
                            else
                                reg_dir_val <= to_unsigned(135, reg_dir_val'length);
                            end if;
                        end if;
                        state <= SOBEL_WRITE_DIR;

                    when SOBEL_WRITE_DIR =>
                        state <= SOBEL_NEXT_PIXEL;

                    when SOBEL_NEXT_PIXEL =>
                        if (reg_sobel_i = reg_rows - 4) and (reg_sobel_j = reg_cols - 4) then
                            state <= INIT_NMS;
                        elsif reg_sobel_j < reg_cols - 4 then
                            reg_sobel_j <= reg_sobel_j + 1;
                            state <= INIT_SOBEL;
                        else
                            reg_sobel_j <= to_unsigned(3, reg_sobel_j'length);
                            reg_sobel_i <= reg_sobel_i + 1;
                            state <= INIT_SOBEL;
                        end if;

                    ----------------------------------------------------------------
                    -- NMS
                    ----------------------------------------------------------------
                    when INIT_NMS =>
                        reg_nms_i <= to_unsigned(4, reg_nms_i'length);
                        reg_nms_j <= to_unsigned(4, reg_nms_j'length);
                        state     <= NMS_READ_CENTER_MAG;

                    when NMS_READ_CENTER_MAG =>
                        state <= NMS_WAIT_CENTER_MAG;

                    when NMS_WAIT_CENTER_MAG =>
                        state <= NMS_LATCH_CENTER_MAG;

                    when NMS_LATCH_CENTER_MAG =>
                        reg_nms_mag <= unsigned(mag_doa);
                        state       <= NMS_READ_DIR;

                    when NMS_READ_DIR =>
                        state <= NMS_WAIT_DIR;

                    when NMS_WAIT_DIR =>
                        state <= NMS_LATCH_DIR;

                    when NMS_LATCH_DIR =>
                        reg_nms_dir <= unsigned(dir_doa);
                        state       <= NMS_SET_NEIGH_ADDRS;

                    when NMS_SET_NEIGH_ADDRS =>
                        if reg_nms_dir = to_unsigned(0, reg_nms_dir'length) then
                            q_addr_int := to_integer(reg_nms_i) * to_integer(reg_cols) + to_integer(reg_nms_j) + 1;
                            r_addr_int := to_integer(reg_nms_i) * to_integer(reg_cols) + to_integer(reg_nms_j) - 1;
                        elsif reg_nms_dir = to_unsigned(45, reg_nms_dir'length) then
                            q_addr_int := (to_integer(reg_nms_i) + 1) * to_integer(reg_cols) + (to_integer(reg_nms_j) - 1);
                            r_addr_int := (to_integer(reg_nms_i) - 1) * to_integer(reg_cols) + (to_integer(reg_nms_j) + 1);
                        elsif reg_nms_dir = to_unsigned(90, reg_nms_dir'length) then
                            q_addr_int := (to_integer(reg_nms_i) + 1) * to_integer(reg_cols) + to_integer(reg_nms_j);
                            r_addr_int := (to_integer(reg_nms_i) - 1) * to_integer(reg_cols) + to_integer(reg_nms_j);
                        else
                            q_addr_int := (to_integer(reg_nms_i) - 1) * to_integer(reg_cols) + (to_integer(reg_nms_j) - 1);
                            r_addr_int := (to_integer(reg_nms_i) + 1) * to_integer(reg_cols) + (to_integer(reg_nms_j) + 1);
                        end if;

                        reg_q_addr <= to_unsigned(q_addr_int, ADDR_WIDTH);
                        reg_r_addr <= to_unsigned(r_addr_int, ADDR_WIDTH);
                        state      <= NMS_READ_Q;

                    when NMS_READ_Q =>
                        state <= NMS_WAIT_Q;

                    when NMS_WAIT_Q =>
                        state <= NMS_LATCH_Q;

                    when NMS_LATCH_Q =>
                        reg_q_mag <= unsigned(mag_doa);
                        state     <= NMS_READ_R;

                    when NMS_READ_R =>
                        state <= NMS_WAIT_R;

                    when NMS_WAIT_R =>
                        state <= NMS_LATCH_R;

                    when NMS_LATCH_R =>
                        reg_r_mag <= unsigned(mag_doa);
                        state     <= NMS_COMPARE;

                    when NMS_COMPARE =>
                        if (reg_nms_mag >= reg_q_mag) and (reg_nms_mag >= reg_r_mag) then
                            reg_nms_out <= reg_nms_mag;
                        else
                            reg_nms_out <= (others => '0');
                        end if;
                        state <= NMS_WRITE;

                    when NMS_WRITE =>
                        state <= NMS_NEXT_PIXEL;

                    when NMS_NEXT_PIXEL =>
                        if (reg_nms_i = reg_rows - 5) and (reg_nms_j = reg_cols - 5) then
                            state <= NMS_DONE;
                        elsif reg_nms_j < reg_cols - 5 then
                            reg_nms_j <= reg_nms_j + 1;
                            state <= NMS_READ_CENTER_MAG;
                        else
                            reg_nms_j <= to_unsigned(4, reg_nms_j'length);
                            reg_nms_i <= reg_nms_i + 1;
                            state <= NMS_READ_CENTER_MAG;
                        end if;

                    when NMS_DONE =>
                        state <= INIT_THRESH;

                    ----------------------------------------------------------------
                    -- THRESH
                    ----------------------------------------------------------------
                    when INIT_THRESH =>
                        reg_thresh_i <= to_unsigned(4, reg_thresh_i'length);
                        reg_thresh_j <= to_unsigned(4, reg_thresh_j'length);
                        state <= THRESH_READ;

                    when THRESH_READ =>
                        state <= THRESH_WAIT;

                    when THRESH_WAIT =>
                        state <= THRESH_LATCH;

                    when THRESH_LATCH =>
                        reg_thresh_pix <= unsigned(nms_doa);
                        state <= THRESH_CLASSIFY;

                    when THRESH_CLASSIFY =>
                        --if to_integer(reg_thresh_pix) >= HIGH_THRESHOLD then
                            --reg_thresh_out <= to_unsigned(STRONG_EDGE, 8);
                        --elsif to_integer(reg_thresh_pix) >= LOW_THRESHOLD then
                            --reg_thresh_out <= to_unsigned(WEAK_EDGE, 8);
                        --else
                            --reg_thresh_out <= (others => '0');
                        --end if;
                    --state <= THRESH_WRITE;
                    
                        if (to_integer(reg_thresh_i) = 113) and (to_integer(reg_thresh_j) = 4) then
                        report "DEBUG THRESH_WRITE row=113 col=4 reg_thresh_pix=" &
                        integer'image(to_integer(reg_thresh_pix)) &
                        " thresh_out=" &
                        integer'image(to_integer(reg_thresh_out)) &
                        " low=" &
                        integer'image(to_integer(unsigned(low_threshold_i))) &
                        " high=" &
                        integer'image(to_integer(unsigned(high_threshold_i)));
                        end if;
                        
                        if to_integer(reg_thresh_pix) >= to_integer(unsigned(high_threshold_i)) then
                                reg_thresh_out <= to_unsigned(STRONG_EDGE, 8);
                        elsif to_integer(reg_thresh_pix) >= to_integer(unsigned(low_threshold_i)) then
                                reg_thresh_out <= to_unsigned(WEAK_EDGE, 8);
                        else
                                reg_thresh_out <= (others => '0');
                        end if;
                    
                    state <= THRESH_WRITE;

                    when THRESH_WRITE =>
                        state <= THRESH_NEXT_PIXEL;

                    when THRESH_NEXT_PIXEL =>
                        if (reg_thresh_i = reg_rows - 5) and (reg_thresh_j = reg_cols - 5) then
                            state <= THRESH_DONE;
                        elsif reg_thresh_j < reg_cols - 5 then
                            reg_thresh_j <= reg_thresh_j + 1;
                            state <= THRESH_READ;
                        else
                            reg_thresh_j <= to_unsigned(4, reg_thresh_j'length);
                            reg_thresh_i <= reg_thresh_i + 1;
                            state <= THRESH_READ;
                        end if;

                    when THRESH_DONE =>
                        state <= INIT_EDGE_COPY;

                    ----------------------------------------------------------------
                    -- EDGE COPY
                    ----------------------------------------------------------------
                    when INIT_EDGE_COPY =>
                        reg_copy_i <= to_unsigned(4, reg_copy_i'length);
                        reg_copy_j <= to_unsigned(4, reg_copy_j'length);
                        state      <= EDGE_COPY_READ;

                    when EDGE_COPY_READ =>
                        state <= EDGE_COPY_WAIT;

                    when EDGE_COPY_WAIT =>
                        state <= EDGE_COPY_LATCH;

                    when EDGE_COPY_LATCH =>
                        reg_copy_pix <= unsigned(thresh_doa);
                        state        <= EDGE_COPY_WRITE;

                    when EDGE_COPY_WRITE =>
                        if (to_integer(reg_copy_i) = 113) and (to_integer(reg_copy_j) = 4) then
                        report "DEBUG EDGE_COPY_WRITE row=113 col=4 copy_pix=" &
                        integer'image(to_integer(reg_copy_pix));
                        end if;
                        state <= EDGE_COPY_NEXT_PIXEL;

                    when EDGE_COPY_NEXT_PIXEL =>
                        if (reg_copy_i = reg_rows - 5) and (reg_copy_j = reg_cols - 5) then
                            state <= EDGE_COPY_DONE;
                        elsif reg_copy_j < reg_cols - 5 then
                            reg_copy_j <= reg_copy_j + 1;
                            state      <= EDGE_COPY_READ;
                        else
                            reg_copy_j <= to_unsigned(4, reg_copy_j'length);
                            reg_copy_i <= reg_copy_i + 1;
                            state      <= EDGE_COPY_READ;
                        end if;

                    when EDGE_COPY_DONE =>
                        state <= INIT_HYST;

                    ----------------------------------------------------------------
                    -- HYST (in-place over EDGE BRAM)
                    ----------------------------------------------------------------
                    when INIT_HYST =>
                        reg_hyst_i         <= to_unsigned(5, reg_hyst_i'length);
                        reg_hyst_j         <= to_unsigned(5, reg_hyst_j'length);
                        --reg_hyst_i         <= to_unsigned(4, reg_hyst_i'length);
                        --reg_hyst_j         <= to_unsigned(4, reg_hyst_j'length);
                        reg_hyst_connected <= '0';
                        state              <= HYST_READ_CENTER;

                    when HYST_READ_CENTER =>
                        hyst_addr_i   := to_integer(reg_hyst_i) * to_integer(reg_cols) + to_integer(reg_hyst_j);
                        reg_hyst_addr <= to_unsigned(hyst_addr_i, ADDR_WIDTH);
                        state         <= HYST_WAIT_CENTER;

                    when HYST_WAIT_CENTER =>
                        state <= HYST_LATCH_CENTER;

                    when HYST_LATCH_CENTER =>
                        reg_hyst_pix <= unsigned(edge_doa);

                        if unsigned(edge_doa) = to_unsigned(STRONG_EDGE, 8) then
                            reg_hyst_out <= to_unsigned(STRONG_EDGE, 8);
                            state        <= HYST_WRITE;
                        elsif unsigned(edge_doa) = to_unsigned(0, 8) then
                            reg_hyst_out <= (others => '0');
                            state        <= HYST_WRITE;
                        else
                            state <= HYST_INIT_NEIGH;
                        end if;

                    when HYST_INIT_NEIGH =>
                        reg_hyst_k         <= -1;
                        reg_hyst_l         <= -1;
                        reg_hyst_connected <= '0';
                        state              <= HYST_READ_NEIGH;

                    when HYST_READ_NEIGH =>
                        if (reg_hyst_k = 0) and (reg_hyst_l = 0) then
                            state <= HYST_NEXT_NEIGH;
                        else
                            hyst_addr_i := (to_integer(reg_hyst_i) + reg_hyst_k) * to_integer(reg_cols) +
                                           (to_integer(reg_hyst_j) + reg_hyst_l);
                            reg_hyst_addr <= to_unsigned(hyst_addr_i, ADDR_WIDTH);
                            state         <= HYST_WAIT_NEIGH;
                        end if;

                    when HYST_WAIT_NEIGH =>
                        state <= HYST_LATCH_NEIGH;

                    when HYST_LATCH_NEIGH =>
                        reg_hyst_neigh <= unsigned(edge_doa);
                            if (to_integer(reg_hyst_i) = 113) and (to_integer(reg_hyst_j) = 4) then
                                report "DEBUG HYST_NEIGH row=113 col=4 k=" &
                                integer'image(reg_hyst_k) &
                                " l=" &
                                integer'image(reg_hyst_l) &
                                " neigh_addr=" &
                                integer'image(to_integer(reg_hyst_addr)) &
                                " edge_doa=" &
                                integer'image(to_integer(unsigned(edge_doa)));
                                end if;
                        state <= HYST_CHECK_NEIGH;

                    when HYST_CHECK_NEIGH =>
                    if reg_hyst_neigh = to_unsigned(STRONG_EDGE, 8) then
                        --if unsigned(edge_doa) = to_unsigned(STRONG_EDGE, 8) then
                            reg_hyst_connected <= '1';
                        end if;
                        state <= HYST_NEXT_NEIGH;

                    when HYST_NEXT_NEIGH =>
                        if (reg_hyst_k = 1) and (reg_hyst_l = 1) then
                            if reg_hyst_connected = '1' then
                                reg_hyst_out <= to_unsigned(STRONG_EDGE, 8);
                            else
                                reg_hyst_out <= (others => '0');
                            end if;
                            state <= HYST_WRITE;
                        elsif reg_hyst_l < 1 then
                            reg_hyst_l <= reg_hyst_l + 1;
                            state      <= HYST_READ_NEIGH;
                        else
                            reg_hyst_l <= -1;
                            reg_hyst_k <= reg_hyst_k + 1;
                            state      <= HYST_READ_NEIGH;
                        end if;

                    when HYST_WRITE =>
                        if (to_integer(reg_hyst_i) = 113) and (to_integer(reg_hyst_j) = 4) then
                        report "DEBUG HYST_WRITE row=113 col=4 hyst_pix=" &
                        integer'image(to_integer(reg_hyst_pix)) &
                        " hyst_out=" &
                        integer'image(to_integer(reg_hyst_out)) &
                        " connected=" &
                        std_logic'image(reg_hyst_connected);
                        end if;
                        state <= HYST_NEXT_PIXEL;

                    when HYST_NEXT_PIXEL =>
                        if (reg_hyst_i = reg_rows - 6) and (reg_hyst_j = reg_cols - 6) then
                        --if (reg_hyst_i = reg_rows - 5) and (reg_hyst_j = reg_cols - 5) then                        
                            state <= HYST_DONE;
                        elsif reg_hyst_j < reg_cols - 6 then
                        --elsif reg_hyst_j < reg_cols - 5 then
                            reg_hyst_j <= reg_hyst_j + 1;
                            state      <= HYST_READ_CENTER;
                        else
                            reg_hyst_j <= to_unsigned(5, reg_hyst_j'length);
                            --reg_hyst_j <= to_unsigned(4, reg_hyst_j'length);
                            reg_hyst_i <= reg_hyst_i + 1;
                            state      <= HYST_READ_CENTER;
                        end if;

                    when HYST_DONE =>
                        state <= DONE;

                    when DONE =>
                        ready_reg <= '1';
                        if start = '0' then
                            state <= IDLE;
                        else
                            state <= DONE;
                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
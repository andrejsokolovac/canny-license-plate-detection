CC := gcc
CFLAGS := -Wall -Wextra -Wpedantic -std=c11 -O2
TARGET := canny_app
SOURCE := canny_app.c

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

clean:
	rm -f $(TARGET)

.PHONY: all clean

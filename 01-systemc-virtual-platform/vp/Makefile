# Kompajler i opcije
CXX = g++
CXXFLAGS = -Wall -std=c++17 -g

# SystemC i OpenCV biblioteke
SYSTEMC_HOME = /usr/local/systemc
OPENCV_FLAGS = $(shell pkg-config --cflags --libs opencv4)
SYSTEMC_FLAGS = -I$(SYSTEMC_HOME)/include -L$(SYSTEMC_HOME)/lib -lsystemc

# Izlazni fajl
TARGET = cpu_test

# Izvorni fajlovi
SRCS = main.cpp cpu.cpp bram.cpp interconnect.cpp hard.cpp utils.cpp
OBJS = $(SRCS:.cpp=.o)

# Pravila
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(SYSTEMC_FLAGS) $(OPENCV_FLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< $(SYSTEMC_FLAGS) $(OPENCV_FLAGS)

clean:
	rm -f $(OBJS) $(TARGET)

run:
	./$(TARGET) 


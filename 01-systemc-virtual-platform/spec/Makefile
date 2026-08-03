# Makefile za C++ projekat sa automatskim OpenCV detekcijom

# Kompajler i opcije
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra

# Automatsko prepoznavanje OpenCV putanja pomoću pkg-config
OPENCV_FLAGS = $(shell pkg-config --cflags --libs opencv4)

# Naziv izvršnog fajla
TARGET = opencv_detection

# Izvorni fajlovi
SRC = opencv_detection.cpp 

# Pravilo za kompajliranje 
$(TARGET): $(SRC) $(HEADERS)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(OPENCV_FLAGS)

# Pravilo za ručno pokretanje 
run: $(TARGET)
	./$(TARGET)

# Pravilo za čišćenje kompajliranih fajlova
clean:
	rm -f $(TARGET)

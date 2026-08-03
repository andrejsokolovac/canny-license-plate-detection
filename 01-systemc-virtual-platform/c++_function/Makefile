# Makefile za C++ projekat sa automatskim OpenCV detekcijom

# Kompajler i opcije
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra

# Automatsko prepoznavanje OpenCV putanja pomoću pkg-config
OPENCV_FLAGS = $(shell pkg-config --cflags --libs opencv4)

# Naziv izvršnog fajla
TARGET = projekat

# Izvorni fajlovi
SRC = projekat.cpp canny_edge.cpp
HEADERS = canny_edge.h

# Pravililo za kompajliranje 
$(TARGET): $(SRC) $(HEADERS)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(OPENCV_FLAGS)

# Pravililo za ručno pokretanje ako je potrebno
run: $(TARGET)
	./$(TARGET)

# Pravililo za čišćenje kompajliranih fajlova
clean:
	rm -f $(TARGET)





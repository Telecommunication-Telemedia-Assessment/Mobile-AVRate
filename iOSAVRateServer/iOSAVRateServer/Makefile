CC = g++
CFLAGS = -Wall 
EXEC_NAME = iOSAVRateServer
INCLUDES =  -I/Users/pierre/Project/Libraries/OpenCV/include/  -I/Users/pierre/Project/Libraries/Include/ 
LIBPATH = -L/Users/pierre/Project/Libraries/OpenCV/lib/ -L/Users/pierre/Project/Libraries/lib/   
LIBS =  -lm
FRAMEWORKS = 
OBJ_FILES = main.o NetworkStream.o 

INSTALL_DIR = /usr/bin

all : $(EXEC_NAME)

clean :
	rm $(EXEC_NAME) $(OBJ_FILES)

$(EXEC_NAME) : $(OBJ_FILES)
	$(CC) -o $(EXEC_NAME) $(OBJ_FILES) $(LIBPATH) $(LIBS) $(FRAMEWORKS)

%.o: %.cpp
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<

%.o: %.cc
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<

%.o: %.c
	gcc $(CFLAGS) $(INCLUDES) -o $@ -c $<

install :
	cp $(EXEC_NAME) $(INSTALL_DIR)


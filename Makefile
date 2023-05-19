# Compiler options
CC = g++
CFLAGS = -DSFML_MAIN -DSPDLOG_COMPILED_LIB -fdiagnostics-color=always -std=c++20 -Isrc -Ilib -IC:/SFML-2.5.1/include
RLSLFLAGS = -L. -lsfml-graphics-2 -lsfml-audio-2 -lsfml-window-2 -lsfml-system-2
DBGLFLAGS = -L. -lsfml-graphics-d-2 -lsfml-audio-d-2 -lsfml-window-d-2 -lsfml-system-d-2
FIND := C:/msys64/usr/bin/find.exe

# Directories
SRCDIR = src
DBGDIR = obj/debug
RLSDIR = obj/release

# Files
SRCS = $(shell $(FIND) $(SRCDIR)/ -type f -name '*.cpp')
DBGOBJS = $(patsubst $(SRCDIR)/%.cpp,$(DBGDIR)/%.o,$(SRCS))
RLSOBJS = $(patsubst $(SRCDIR)/%.cpp,$(RLSDIR)/%.o,$(SRCS))
EXEC = main-debug.exe main-release.exe

# Generate a list of header dependencies for each source file
DBGDEPS = $(DBGOBJS:.o=.d)
RLSDEPS = $(RLSOBJS:.o=.d)

# Targets
.PHONY: debug release clean run-debug run-release

# Include the header dependencies for each source file
-include $(DBGDEPS) $(RLSDEPS)

debug: CFLAGS += -g
debug: main-debug.exe

release: CFLAGS += -O2 -DNDEBUG
release: main-release.exe

main-debug.exe: $(DBGOBJS)
	$(CC) $(CFLAGS) $(DBGLFLAGS) -o $@ $^

main-release.exe: $(RLSOBJS)
	$(CC) $(CFLAGS) $(RLSLFLAGS) -o $@ $^

$(DBGDIR)/%.o: $(SRCDIR)/%.cpp | $(DBGDIR)
	$(CC) $(CFLAGS) -c -o $@ $< -MMD -MP -MF $(@:.o=.d) -MT $@

$(RLSDIR)/%.o: $(SRCDIR)/%.cpp | $(RLSDIR)
	$(CC) $(CFLAGS) -c -o $@ $< -MMD -MP -MF $(@:.o=.d) -MT $@

$(DBGDIR) $(RLSDIR):
	mkdir -p $@ ;
	rsync -a --exclude="*.cpp" --exclude="*.h" src/ $@/

clean:
	rm -rf $(DBGDIR) $(RLSDIR) $(EXEC)

run-debug: debug
	gdb -ex run --args main-debug.exe

run-release: release
	./main-release.exe
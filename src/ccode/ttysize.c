#ifndef _ttysize
#define _GNU_SOURCE
#define _ttysize

#include <stdio.h>
#include <sys/ioctl.h>
#include <signal.h>

struct winsize sz;

int _tty_row;
int _tty_col;

int get_tty_height(){
    if(_tty_row < 1){
        return 24;
    }
    return _tty_row;
}
int get_tty_width(){
    if(_tty_col < 1){
        return 80;
    }
    return _tty_col;
}

void calculate_size( int signum ){
        ioctl( 0, TIOCGWINSZ, &sz );
        _tty_row = sz.ws_row ;
        _tty_col = sz.ws_col;
}


void tty_size_init(){
        signal( SIGWINCH, calculate_size );
        calculate_size(SIGWINCH);
}

#endif

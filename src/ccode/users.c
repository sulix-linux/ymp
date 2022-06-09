#include <unistd.h>
#include <pwd.h>

int is_root(){
  return 0 == getuid();
}

int get_uid_by_user(char* username){
    struct passwd *p;
    if((p = getpwnam(username)) == NULL){
        return p->pw_uid;
    }
    return -1;
}

int switch_user(char* username){
    uid_t u = get_uid_by_user(username);
    if(u == setuid(u)){
        return 1;
    }
    return 0;
}
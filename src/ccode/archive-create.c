#ifndef _archive
#define _archive


#define zip 0
#define tar 1
#define p7zip 2
#define cpio 3
#define ar 4

#define filter_none 0
#define filter_gzip 1
#define filter_xz 2

int aformat = 1;
int afilter = 0;


#ifndef no_libarchive
#include <sys/types.h>

#include <sys/stat.h>

#include <archive.h>
#include <archive_entry.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <limits.h>


#ifndef get_bool
int get_bool(char*variable);
#endif

void write_archive(const char *outname, const char **filename) {
  struct archive *a;
  struct archive_entry *entry;
  struct stat st;
  char buff[8192];
  int len;
  int fd;

  a = archive_write_new();
  // compress format
  if(afilter == filter_gzip){
      archive_write_add_filter_gzip(a);
  }else if(afilter == filter_xz){
      archive_write_add_filter_xz(a);
  }else{
      archive_write_add_filter_none(a);
  }
  // archive format
  if(aformat == tar){
      archive_write_set_format_gnutar(a);
  }else if (aformat == p7zip){
      archive_write_set_format_7zip(a);
  }else if (aformat == cpio){
      archive_write_set_format_cpio(a);
  }else if (aformat == ar){
      archive_write_set_format_ar_bsd(a);
  }else{
      archive_write_set_format_zip(a);
  }
  archive_write_open_filename(a, outname);
  char link[PATH_MAX];
  #ifdef DEBUG
  char* type;
  #endif
  while (*filename) {
    lstat(*filename, &st);
    entry = archive_entry_new(); 
    archive_entry_set_pathname(entry, *filename);
    archive_entry_set_size(entry, st.st_size);
    switch (st.st_mode & S_IFMT) {
            case S_IFBLK:
                 // block device
                archive_entry_set_filetype(entry, AE_IFBLK);
                #ifdef DEBUG
                type = "block device";
                #endif
                break;
            case S_IFCHR:
                // character device
                #ifdef DEBUG
                type = "character device";
                #endif
                archive_entry_set_filetype(entry, AE_IFCHR);
                break;
            case S_IFDIR:
                // directory
                #ifdef DEBUG
                type = "directory";
                #endif
                archive_entry_set_filetype(entry, AE_IFDIR);
                break;
            case S_IFIFO:
                // FIFO/pipe
                #ifdef DEBUG
                type = "fifo";
                #endif
                archive_entry_set_filetype(entry, AE_IFIFO);
                break;
            case S_IFLNK:
                // symlink
                #ifdef DEBUG
                type = "symlink";
                #endif
                len = readlink(*filename,link,sizeof(link));
                if(len < 0){
                    fprintf(stderr,"Broken symlink: %s\n",*filename);
                    continue;
                }
                link[len] = '\0';
                #ifdef DEBUG
                if(get_bool("debug")){
                    fprintf(stderr,"Symlink: %s %s\n",*filename, link);
                }
                #endif
                archive_entry_set_filetype(entry, AE_IFLNK);
                archive_entry_set_symlink(entry, link);
                break;
            case S_IFREG:
                // regular file
                #ifdef DEBUG
                type = "file";
                #endif
                archive_entry_set_filetype(entry, AE_IFREG);
                break;
            case S_IFSOCK:
                // socket
                #ifdef DEBUG
                type = "socket";
                #endif
                archive_entry_set_filetype(entry, AE_IFSOCK);
                break;                
            default:
                // unknown
                #ifdef DEBUG
                type = "unknown";
                #endif
                archive_entry_set_filetype(entry, AE_IFREG);
                fprintf(stderr,"Unknown enty detected: %s (%d)\n",*filename,st.st_mode);
                continue;
    }
    #ifdef DEBUG
    if(get_bool("debug")){
        fprintf(stderr,"Compress: %s type %s (%d)\n",*filename,type,st.st_mode);
    }
    #endif
    archive_entry_set_perm(entry, 0644);
    archive_write_header(a, entry);
    fd = open(*filename, O_RDONLY);
    len = read(fd, buff, sizeof(buff));
    while ( len > 0 ) {
        archive_write_data(a, buff, len);
        len = read(fd, buff, sizeof(buff));
    }
    close(fd);
    archive_entry_free(entry);
    filename++;
  }
  archive_write_close(a);
  archive_write_free(a);
}
#endif
#endif

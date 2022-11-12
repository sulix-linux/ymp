private string[] quarantine_file_cache_list;
private string[] quarantine_file_conflict_list;
private string[] quarantine_file_broken_list;

public void quarantine_reset(){
  remove_all(get_storage()+"/quarantine/");
  create_dir(get_storage()+"/quarantine/rootfs");
  create_dir(get_storage()+"/quarantine/files");
  create_dir(get_storage()+"/quarantine/links");
  create_dir(get_storage()+"/quarantine/metadata");
}
//DOC: `bool quarantine_validate_files():`
//DOC: check quarantine file hashes
public bool quarantine_validate_files(){
    if(get_bool("ignore-quarantine")){
        warning("Quarantine validation disabled");
        return true;
    }
    print(colorize("Quarantine validation",yellow));
    // reset lists
    quarantine_file_cache_list = {};
    quarantine_file_conflict_list = {};
    quarantine_file_broken_list = {};
    //get quarantine file store and list
    string rootfs_files = get_storage()+"/quarantine/files/";
    string rootfs_links = get_storage()+"/quarantine/links/";
    foreach(string files_list in listdir(rootfs_files)){
        info("Validate quarantine for: "+files_list);
        // file list format xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx /path/to/file
        // uses sha1sum
        string file_data = readfile(rootfs_files+files_list);
        foreach(string line in ssplit(file_data,"\n")){
            if(line.length > 41){
                // fetch absolute file path
                string path = line[41:];
                path = path.strip();
                string file_path = get_storage()+"/quarantine/rootfs/"+path;
                // check file conflict
                info("Validating: "+path);
                if(file_path in quarantine_file_cache_list){
                    warning("File conflict detected: /"+path);
                    quarantine_file_conflict_list += file_path;
                    continue;
                }
                quarantine_file_cache_list += file_path;
                if(!isfile(file_path)){
                    warning("Package file missing: /"+file_path);
                    quarantine_file_broken_list += file_path;
                    continue;
                }
                // calculate and check sha1sum values
                string sha1sum = line[0:40];
                string calculated_sha1sum = calculate_sha1sum(file_path);
                if(sha1sum != calculated_sha1sum){
                    warning("Broken file detected: /"+path);
                    quarantine_file_broken_list += file_path;
                    continue;
                }
            }
        }
    }
    foreach(string links_list in listdir(rootfs_links)){
        info("Validate quarantine for: "+links_list);
        string link_data = readfile(rootfs_links+links_list);
        foreach(string line in ssplit(link_data,"\n")){
            if(" " in line){
                string path = ssplit(line," ")[0];
                string target = ssplit(line," ")[1];
                string link_path = get_storage()+"/quarantine/rootfs/"+path;
                // check broken symlink
                info("Validating: "+path);
                if(target != sreadlink(link_path)){
                    warning("Broken symlink detected: /"+path);
                    quarantine_file_broken_list += link_path;
                    continue;
                }
                // check file conflict
                if(link_path in quarantine_file_cache_list){
                    warning("Symlink conflict detected: /"+path);
                    quarantine_file_conflict_list += link_path;
                    continue;
                }
                if(!issymlink(link_path)){
                    warning("Package symlink missing: /"+link_path);
                    quarantine_file_broken_list += link_path;
                    continue;
                }
                quarantine_file_cache_list += link_path;
            }
        }
    }
    if(quarantine_file_conflict_list.length>0 || quarantine_file_broken_list.length >0){
        return false;
    }
    return true;
}
//DOC: `void quarantine_install():`
//DOC: install quarantine files to rootfs
public void quarantine_install(){
    info("Quarantine installation");
    string rootfs = srealpath(get_storage()+"/quarantine/rootfs/");
    string files = srealpath(get_storage()+"/quarantine/files/");
    string links = srealpath(get_storage()+"/quarantine/links/");
    string metadata = srealpath(get_storage()+"/quarantine/metadata/");
    foreach(string fname in find(rootfs)){
        string ftarget = get_destdir()+fname[rootfs.length:];
        
        string fdir = sdirname(ftarget);
        debug("Installing: "+fname+" => "+ftarget);
        create_dir(fdir);
        GLib.FileUtils.chmod(fdir,0755);
        if(is_root()){
            Posix.chown(fdir,0,0);
        }
        if(isfile(fname)){
            move_file(fname,ftarget);
            GLib.FileUtils.chmod(ftarget,0755);
            if(is_root()){
                Posix.chown(ftarget,0,0);
            }
        }
    }
    fs_sync();
    foreach(string fname in listdir(files)){
        if(isfile(get_storage()+"/files/"+fname)){
            remove_file(get_storage()+"/files/"+fname);
        }
        move_file(files+"/"+fname,get_storage()+"/files/"+fname);
    }
    fs_sync();
    foreach(string fname in listdir(links)){
        if(isfile(get_storage()+"/links/"+fname)){
            remove_file(get_storage()+"/links/"+fname);
        }
        move_file(links+"/"+fname,get_storage()+"/links/"+fname);
    }
    fs_sync();
    foreach(string fname in listdir(metadata)){
        if(isfile(get_storage()+"/metadata/"+fname)){
            remove_file(get_storage()+"/metadata/"+fname);
        }
        move_file(metadata+"/"+fname,get_storage()+"/metadata/"+fname);
    }
    fs_sync();
}

private void quarantine_import_from_path(string path){
    info("Quarantine import");
    string rootfs = srealpath(get_storage()+"/quarantine/rootfs/");
    string files = srealpath(get_storage()+"/quarantine/files/");
    string links = srealpath(get_storage()+"/quarantine/links/");
    string metadata = srealpath(get_storage()+"/quarantine/metadata/");
    package p = new package();
    p.load(path+"/metadata.yaml");
    move_file(path+"/metadata.yaml",metadata+"/"+p.name+".yaml");
    move_file(path+"/files",files+"/"+p.name);
    move_file(path+"/links",links+"/"+p.name);
    foreach(string fname in find(path)){
        string ftarget = fname[path.length:];
        if(isfile(fname)){
            create_dir(rootfs+sdirname(ftarget));
            move_file(fname,rootfs+ftarget);
        }
    }
    error(2);
    fs_sync();
}

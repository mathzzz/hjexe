#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

#define MIN(a, b) ((a<b) ? (a) : (b))
#define ENV_LINE_MAXLEN 4096
#define ENV_FILE_MAXSIZE   (1024*1024)
#define PRINT_BUF_SIZE  (1024*64)
#define ENV_MAPBUF_SIZE  (1024*32)
#define ENV_FILE     "/tmp/.env"


static inline int 
sncat(char *buf, size_t bufsize, char *chip)
{
	int len = 0;
	int chip_size = strlen(chip);
	if(chip_size+1 < bufsize && bufsize > 0) {
        strncpy(buf, chip, chip_size+1);
		len = chip_size;
	}
	return len;
}

static char envmap[16 * 1024];

static char envbuf[PRINT_BUF_SIZE]; 
int 
hjexe_env_quick_search(char *env)
{
	int foundit, envlen;
	char *p1, *p2;

	envlen = strlen(env);
	foundit = 0;
	for(p1 = envmap, p2 = strchr(p1, '\n'); p2; p1=p2+1, p2=strchr(p1,'\n')) {
		if((p2-p1) == envlen && 0 == memcmp(env, p1, envlen)) {
			foundit = 1;
		}
	}

	return foundit;
}


static void 
hjexe_print_diff_args(int argc, char **argv, char * const *envp)
{
	ssize_t size, hjlen;	
	struct stat buf;
	int i,fd, len; 
	time_t cur;
	fd = open(ENV_FILE, O_RDONLY|O_CLOEXEC);
	if(-1 == fd)
		return;

	int fd_fifo = open("/tmp/log.fifo", O_RDWR|O_CLOEXEC);
	if(-1 == fd)
		return;

	fstat(fd, &buf);
	if(buf.st_size > sizeof(envmap))
		return;
	
	size = read(fd, envmap, buf.st_size);
	if(size == -1)
		return;

	cur = time(NULL);
	len = snprintf(envbuf, sizeof(envbuf), "### cur=%9ld, cli:ppid=%5d, pid=%5d\n",
			time(NULL), getppid(), getpid());

	for(i=0; envp[i]; i++){
		if(0 == hjexe_env_quick_search(envp[i]) && memcmp((envp[i]),"_=", 2) ){
			len += snprintf(envbuf+len, sizeof(envbuf)-len, "%s\n", envp[i]);
		}	
	}
	
	len += snprintf(envbuf + len, sizeof(envbuf)-len, "echo %9ld; cd %s; ", cur, getenv("PWD") ?: "");
	for(i=0; i<argc; i++) {
		len += snprintf(envbuf+len, sizeof(envbuf)-len, "%s ", argv[i]);
	}

	len += sncat(envbuf+len, sizeof(envbuf)-len, "\n\n");

	size = write(fd_fifo, envbuf, len);

	close(fd);
	close(fd_fifo);

	return;
}

#define BASENAME(full) (strrchr(full, '/') + 1)

static inline char *
getbasedir(char *fullpath)
{
	char *pc;
	if(fullpath[0] == '/') {
		pc = BASENAME(fullpath);
		*(pc - 1) = '\0';
	}

	return fullpath;
}


static int 
exehj_is_open(char *bname)
{
	char buf[256];
	int len = 0; 
	char *home = getenv("HOME") ?: "/tmp";

	len += sncat(buf+len, sizeof(buf)-len, home);
	len += sncat(buf+len, sizeof(buf)-len, "/.hj/");
	len += sncat(buf+len, sizeof(buf)-len, bname);
	len += sncat(buf+len, sizeof(buf)-len, ".open");

	if(0 == access(buf, F_OK))
		return 1;

	return 0;
}

char *hj_find_command_in_path(char *name)
{
    static char buf[512];
    char *path = getenv("PATH");
    char *p1, *p2 = NULL;
    size_t len;
	
    if(NULL == path)
        return NULL;

    for(p1 = path; p2=strchr(p1, ':'); p1=p2+1) {
        len = p2 - p1;
        if(len > 0 && len < sizeof(buf)) {
            memcpy(buf, p1, len);
            buf[len] = '/';
            sncat(buf+len+1, sizeof(buf)-len-1,  name);
            if(0 ==  access(buf, X_OK))
                return buf;
        }
    }

	len = sncat(buf, sizeof(buf), getenv("PWD"));
	len += sncat(buf-len, sizeof(buf)+len, "/");
	len += sncat(buf-len, sizeof(buf)+len, name); 
	if(0 == access(buf, X_OK))
		return buf;

    return NULL;
}

static inline char *
findlinkraw(char *fullpath)
{
	char *link = fullpath;
	static char buf[512];
	char linkbuf[512];
	long len;
	for(; (len=readlink(link, linkbuf, sizeof(linkbuf))) > 0; link=linkbuf) {
		linkbuf[len] = '\0';
		if(linkbuf[0] == '/') {//abosulate path
			len = sncat(buf, sizeof(buf), linkbuf);
		} else {
			strncpy(buf, fullpath, sizeof(buf));
			char *pc = strrchr(buf, '/') + 1;
			*pc = '\0';
			len = pc - buf;
			len += sncat(buf+len, sizeof(buf)-len, linkbuf);
		}
		len += sncat(buf+len, sizeof(buf)-len, ".raw");	
		if(0 == access(buf, X_OK)) 
			return buf;
		buf[len-strlen(".raw")] = 0;
	}

	return NULL;
}

int main(int argc, char **argv, char **envp)
{
	int len;
	char buf[256];
	char realpath[512];
	char *bname = BASENAME(argv[0]);
    char *pathdir = hj_find_command_in_path(bname);
	if(0 == strcmp("hjexe", bname)){
		fprintf(stderr, "install cmd1,cmd2,...\n\n");
		return 0;
	}
	
	if(exehj_is_open(bname)) {
		unsetenv("LS_COLORS");
		hjexe_print_diff_args(argc, argv, envp);
	}	

	if(argv[0][0] == '/') { // absulote path
		len = sncat(buf, sizeof(buf), argv[0]);
	} else if (argv[0][0] == '.') { // current work dir
		len = sncat(buf, sizeof(buf), getenv("PWD"));
		len += sncat(buf+len, sizeof(buf)-len, "/");
		len += sncat(buf+len, sizeof(buf)-len, argv[0]);
	} else if(pathdir != NULL){
		//len = readlink("/proc/self/exe", realpath, sizeof(realpath));
        len = sncat(buf, sizeof(buf), pathdir);
        len += sncat(buf+len, sizeof(buf)-len, bname);
    } else {
        fprintf(stderr, "not found %s in %s\n", argv[0], getenv("PATH")); 
        return -1;
    }
	
	len += sncat(buf+len, sizeof(buf)-len, ".raw");
	
	if(0 == access(buf, X_OK))
		execve(buf, argv, envp);

	char *linkraw;
	buf[len-strlen(".raw")] = 0;
	linkraw=findlinkraw(buf);
	if(linkraw)
		execve(linkraw, argv, envp);	

	fprintf(stderr, "no such file or permission deny:%s\n", buf);
	return -1;
}


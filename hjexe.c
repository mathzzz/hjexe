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
#define EXE_SUFFIX   ".raw"   /* /bin/ping.raw*/
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

static inline char *
getexename(char *namepath)
{
	char *cmd = namepath;
	char *cur = NULL;
	for(cur = namepath; *cur; cur++)
		if(*cur == '/')
			cmd = cur + 1;
	
	return cmd;
}

static int 
exehj_is_open(char *exename)
{
	char buf[256];
	int len = 0; 
	char *home = getenv("HOME") ?: "/tmp";

	len += sncat(buf+len, sizeof(buf)-len, home);
	len += sncat(buf+len, sizeof(buf)-len, "/.hj/");
	len += sncat(buf+len, sizeof(buf)-len, exename);
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

    return NULL;
}

int main(int argc, char **argv, char **envp)
{
	int len;
	char buf[256];
	char *exename = getexename(argv[0]);
    char *fullpath;
	if(0 == strcmp("hjexe", exename)){
		fprintf(stderr, "install cmd1,cmd2,...\n\n");
		return 0;
	}
	
	if(exehj_is_open(exename)) {
		unsetenv("LS_COLORS");
		hjexe_print_diff_args(argc, argv, envp);
	}	

	if(strchr(argv[0], '/')) { // absulote path
		len = sncat(buf, sizeof(buf), argv[0]);
	} else if(fullpath = hj_find_command_in_path(argv[0])){
		//len = readlink("/proc/self/exe", realpath, sizeof(realpath));
        len = sncat(buf, sizeof(buf), fullpath);
    } else {
        fprintf(stderr, "not found %s in %s\n", argv[0], getenv("PATH")); 
        return -1;
    }
	
	len += sncat(buf+len, sizeof(buf)-len, EXE_SUFFIX);
	return execve(buf, argv, envp);
}


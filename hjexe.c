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
#define ENV_DIFF_BUF  (1024*16)
#define EXE_SUFFIX   ".raw"   /* /bin/ping.raw*/
#define ENV_FILE     "/tmp/.env"


static inline int 
str_ncat(char *buf, size_t bufsize, char *chip, size_t chip_size)
{
	int len = 0;
	if(chip_size < bufsize-1 ) {
		strcat(buf, chip);
		len = chip_size;
	}
	return len;
}

static char envmap[16 * 1024];

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
	char envbuf[ENV_DIFF_BUF];
	
	fd = open(ENV_FILE, O_RDONLY|O_CLOEXEC);
	if(-1 == fd)
		return;

	fstat(fd, &buf);
	if(buf.st_size > sizeof(envmap))
		return;
	
	size = read(fd, envmap, buf.st_size);
	if(size == -1)
		return;

	len = 0;
	len += snprintf(envbuf, sizeof(envbuf), "### cur=%9d, cli:ppid=%5d, pid=%5d\n",
			time(NULL), getppid(), getpid());

	for(i=0; envp[i]; i++){
		if(0 == hjexe_env_quick_search(envp[i]) && memcmp((envp[i]),"_=", 2) ){
			len += snprintf(envbuf+len, sizeof(envbuf)-len, "export %s\n", envp[i]);
		}	
	}
	
	len += snprintf(envbuf + len, sizeof(envbuf)-len, "cd %s; ", getenv("PWD") ?: "");
	for(i=0; i<argc; i++) {
		len += snprintf(envbuf+len, sizeof(envbuf)-len, "\"%s\" ", argv[i]);
	}
	
	fprintf(stderr, "%s\n\n", envbuf);
	close(fd);

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

	len += str_ncat(buf+len, sizeof(buf)-len, home,    strlen(home));
	len += str_ncat(buf+len, sizeof(buf)-len, "/.hj/",  strlen(".hj/"));
	len += str_ncat(buf+len, sizeof(buf)-len, exename, strlen(exename));
	len += str_ncat(buf+len, sizeof(buf)-len, ".open", strlen(".open"));

	if(0 == access(buf, F_OK))
		return 1;

	return 0;
}


int main(int argc, char **argv, char **envp)
{
	int len;
	char buf[256];
	char *exename = getexename(argv[0]);

	if(exehj_is_open(exename)) {
		unsetenv("LS_COLORS");
		hjexe_print_diff_args(argc, argv, envp);
	}	

	if(argv[0][0] == '/' || argv[0][0] == '.') {
		execve(argv[0], argv, envp);
	} else {
		len = readlink("/proc/self/exe", buf, sizeof(buf));
		len += str_ncat(buf+len, sizeof(buf)-len, EXE_SUFFIX, strlen(EXE_SUFFIX));
		execve(buf, argv, envp); 
	}

	return 0;
}


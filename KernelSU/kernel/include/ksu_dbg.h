#ifndef __KSU_H_DBG
#define __KSU_H_DBG

// shell-readable debug log. temporary diagnostics.

#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/vmalloc.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/kthread.h>
#include <linux/delay.h>

#define KSU_DBG_BUF_SIZE 8192

static char ksu_dbg_buf[KSU_DBG_BUF_SIZE];
static int ksu_dbg_len;
static int ksu_dbg_saved_len;

static void ksu_dbg_log(const char *fmt, ...)
{
	va_list args;
	int n;

	if (ksu_dbg_len >= KSU_DBG_BUF_SIZE - 1)
		return;

	va_start(args, fmt);
	n = vscnprintf(ksu_dbg_buf + ksu_dbg_len, KSU_DBG_BUF_SIZE - ksu_dbg_len, fmt, args);
	va_end(args);

	if (n > 0)
		ksu_dbg_len += n;
}

static int ksu_dbg_show(struct seq_file *m, void *v)
{
	seq_write(m, ksu_dbg_buf, ksu_dbg_len);
	return 0;
}

static int ksu_dbg_open(struct inode *inode, struct file *file)
{
	return single_open(file, ksu_dbg_show, NULL);
}

static const struct file_operations ksu_dbg_fops = {
	.open = ksu_dbg_open,
	.read = seq_read,
	.llseek = seq_lseek,
	.release = single_release,
};

static void ksu_dbg_write_file(const char *path)
{
	struct file *f;
	loff_t pos = 0;

	f = filp_open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (IS_ERR(f))
		return;

	kernel_write(f, ksu_dbg_buf, ksu_dbg_len, &pos);
	filp_close(f, NULL);
}

static void ksu_dbg_flush(void)
{
	if (ksu_dbg_len == 0 || ksu_dbg_len == ksu_dbg_saved_len)
		return;

	ksu_dbg_saved_len = ksu_dbg_len;
	ksu_dbg_write_file("/data/local/tmp/ksu_dbg.log");
	ksu_dbg_write_file("/cache/ksu_dbg.log");
}

static int ksu_dbg_thread(void *data)
{
	while (!kthread_should_stop()) {
		msleep(10000);
		ksu_dbg_flush();
	}
	return 0;
}

static void ksu_dbg_init(void)
{
	proc_create("ksu_dbg", 0444, NULL, &ksu_dbg_fops);
	kthread_run(ksu_dbg_thread, NULL, "ksu_dbg");
}

#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main() {
    const char *red = "\033[31m";
    const char *reset = "\033[0m";

    char user[256], host[256], os[256], kernel[256] = "Unknown";

    snprintf(user, sizeof(user), "%s", getenv("USER"));
    gethostname(host, sizeof(host));

    FILE *os_file = fopen("/etc/os-release", "r");
    if (os_file) {
        char line[256];
        while (fgets(line, sizeof(line), os_file)) {
            if (strstr(line, "PRETTY_NAME")) {
                char *start = strchr(line, '=') + 2;
                char *end = strrchr(line, '"');
                if (start && end) {
                    *end = '\0';
                    snprintf(os, sizeof(os), "%s", start);
                }
                break;
            }
        }
        fclose(os_file);
    }

    FILE *kern_file = fopen("/proc/sys/kernel/osrelease", "r");
    if (kern_file) {
        fgets(kernel, sizeof(kernel), kern_file);
        char *newline = strchr(kernel, '\n');
        if (newline) *newline = '\0';
        fclose(kern_file);
    }

    float uptime_seconds = 0;
    FILE *uptime_file = fopen("/proc/uptime", "r");
    if (uptime_file) {
        fscanf(uptime_file, "%f", &uptime_seconds);
        fclose(uptime_file);
    }
    int uptime_hours = (int)uptime_seconds / 3600;
    int uptime_minutes = ((int)uptime_seconds / 60) % 60;
    char uptime[50];
    if (uptime_hours == 0) {
        snprintf(uptime, sizeof(uptime), "%d minutes", uptime_minutes);
    } else {
        snprintf(uptime, sizeof(uptime), "%d hours, %d minutes", uptime_hours, uptime_minutes);
    }

    int pkgs = 0;
    FILE *pkgs_file = popen("pacman -Qq | wc -l", "r");
    if (pkgs_file) {
        fscanf(pkgs_file, "%d", &pkgs);
        pclose(pkgs_file);
    }

    int total = 0, available = 0;
    FILE *meminfo_file = fopen("/proc/meminfo", "r");
    if (meminfo_file) {
        char line[256];
        while (fgets(line, sizeof(line), meminfo_file)) {
            if (strstr(line, "MemTotal")) {
                total = atoi(line + 9) / 1024;
            } else if (strstr(line, "MemAvailable")) {
                available = atoi(line + 13) / 1024;
            }
        }
        fclose(meminfo_file);
    }
    int mem_used = total - available;

    char cpu[256] = "Unknown";
    FILE *cpu_file = fopen("/proc/cpuinfo", "r");
    if (cpu_file) {
        char line[256];
        while (fgets(line, sizeof(line), cpu_file)) {
            if (strstr(line, "model name")) {
                char *start = strchr(line, ':') + 2;
                if (start) {
                    char *end = strchr(start, '\n');
                    if (end) *end = '\0';
                    snprintf(cpu, sizeof(cpu), "%s", start);
                }
                break;
            }
        }
        fclose(cpu_file);
    }

    char gpu[256] = "unknown (will try to add amd support later)";
    FILE *gpu_file = fopen("/sys/class/drm/card0/device/driver/module", "r");
    if (gpu_file) {
        fgets(gpu, sizeof(gpu), gpu_file);
        fclose(gpu_file);
        if (strstr(gpu, "nvidia")) {
            snprintf(gpu, sizeof(gpu), "NVIDIA GPU");
        }
    }

    printf("%s", red);
    printf("       /\\       %s@%s\n", user, host);
    printf("      /  \\      os: %s\n", os);
    printf("     /\\   \\     kernel: %s\n", kernel);
    printf("    /      \\    uptime: %s\n", uptime);
    printf("   /   ,,   \\   packages: %d\n", pkgs);
    printf("  /   |  |  -   memory: %dM / %dM\n", mem_used, total);
    printf(" /_-''    ''-_\\ cpu: %s\n", cpu);
    printf("                gpu: %s\n", gpu);
    printf("%s", reset);

    return 0;
}

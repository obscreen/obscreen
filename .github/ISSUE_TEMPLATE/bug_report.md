---
name: Bug report
about: Create a report to help us improve
title: "[BUG] "
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Hardware (please complete the following information):**
 - *Device*: `Raspberry Xb+`
 - *OS*: `Raspbian vXX` [use command *lsb_release -a*]
 - *Architecture*: `armvX` [use command *uname -a*]

**Sofware (please complete the following information):**
 - *Obscreen version*: `v1.XX`
 - *Installation method*: `Docker` or `System`
 - *Browser*: `Chromium` or `Chrome`
 - *Player method*: `Systemd with obscreen-player.service` or `Manually`

**Additional context**
Add any other context about the problem here.

**Extra (Recommended)**
You can send us a backup of your data to help speed up the debugging process. Please ensure that no sensitive data is included in your slides and follow these steps:
```bash
cd obscreen
tar -vcf data.tar data/
```
Afterward, attach the `data.tar` file to your issue attachment.
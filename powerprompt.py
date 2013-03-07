#!/usr/bin/env python2
# -*- coding: utf-8 -*-

# Inspired by Vim Powerline by Kim Silkebækken
# Forked from Powerline Bash by Shrey Banga
# Rewritten as Powerline Zsh by Chien Wei Huang
# Further modified by me, totte <totte@tott.es>

import os
import subprocess
import sys
import re

class Powerline:
    separator = '⮀'
    separator_thin='⮁'
    LSQESCRSQ = '\\[\\e%s\\]'
    reset = ' %f%k'

    def __init__(self):
        self.segments = []

    def color(self, prefix, code):
        if prefix == '38':
            return '%%F{%s}' % code
        elif prefix == '48':
            return '%%K{%s}' % code

    def fgcolor(self, code):
        return self.color('38', code)

    def bgcolor(self, code):
        return self.color('48', code)

    def append(self, segment):
        self.segments.append(segment)

    def draw(self):
        return (''.join((s[0].draw(self, s[1]) for s in zip(self.segments, self.segments[1:]+[None])))
            + self.reset)

class Segment:
    def __init__(self, content, fg, bg, separator=Powerline.separator, separator_fg=None):
        self.content = content
        self.fg = fg
        self.bg = bg
        self.separator = separator
        self.separator_fg = separator_fg or bg

    def draw(self, powerline, next_segment=None):
        if next_segment:
            separator_bg = powerline.bgcolor(next_segment.bg)
        else:
            separator_bg = powerline.reset

        return ''.join((
            powerline.fgcolor(self.fg),
            powerline.bgcolor(self.bg),
            self.content,
            separator_bg,
            powerline.fgcolor(self.separator_fg),
            self.separator))

def add_cwd_segment(powerline, cwd, maxdepth):
    home = os.getenv('HOME')
    cwd = os.getenv('PWD')

    if cwd.find(home) == 0:
        cwd = cwd.replace(home, '~', 1)

    if cwd[0] == '/':
        cwd = cwd[1:]

    names = cwd.split('/')
    if len(names) > maxdepth:
        names = names[:2] + ['⋯ '] + names[2-maxdepth:]

    for n in names[:-1]:
        powerline.append(Segment(' %s ' % n, 250, 237, Powerline.separator_thin, 244))
    powerline.append(Segment(' %s ' % names[-1], 254, 237))

def get_git_status():
    has_pending_commits = True
    has_untracked_files = False
    origin_position = ""
    output = subprocess.Popen(['git', 'status'], stdout=subprocess.PIPE).communicate()[0]
    for line in output.split(b'\n'):
        origin_status = re.findall("Your branch is (ahead|behind).*?(\d+) comm", line)
        if len(origin_status) > 0:
            origin_position = " %d" % int(origin_status[0][1])
            if origin_status[0][0] == 'behind':
                origin_position += '⇣'
            if origin_status[0][0] == 'ahead':
                origin_position += '⇡'

        if line.find('nothing to commit (working directory clean)') >= 0:
            has_pending_commits = False
        if line.find('Untracked files') >= 0:
            has_untracked_files = True
    return has_pending_commits, has_untracked_files, origin_position

def add_git_segment(powerline, cwd):
    green = 112
    red = 161
    p1 = subprocess.Popen(['git', 'branch'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p2 = subprocess.Popen(['grep', '-e', '\\*'], stdin=p1.stdout, stdout=subprocess.PIPE)
    output = p2.communicate()[0].strip()
    if len(output) == 0:
        return False
    branch = output.rstrip()[2:]
    has_pending_commits, has_untracked_files, origin_position = get_git_status()
    branch += origin_position
    if has_untracked_files:
        branch += ' +'
    bg = green
    fg = 0
    if has_pending_commits:
        bg = red
        fg = 15
    powerline.append(Segment(' %s ' % branch, fg, bg))
    return True

def add_repo_segment(powerline, cwd):
    for add_repo_segment in [add_git_segment]:
        try:
            if add_repo_segment(p, cwd): return
        except subprocess.CalledProcessError:
            pass
        except OSError:
            pass

def add_virtual_env_segment(powerline, cwd):
    env = os.getenv("VIRTUAL_ENV")
    if env == None:
        return False
    env_name = os.path.basename(env)
    bg = 35
    fg = 22
    powerline.append(Segment(' %s ' % env_name, fg, bg))
    return True

def add_root_indicator(powerline, error):
    bg = 236
    fg = 15
    if int(error) != 0:
        fg = 15
        bg = 161
    powerline.append(Segment('', fg, bg))

if __name__ == '__main__':
    p = Powerline()
    cwd = os.getcwd()
    add_virtual_env_segment(p, cwd)
    p.append(Segment(' $USER ', 250, 240))
    p.append(Segment(' $HOST ', 250, 238))
    add_cwd_segment(p, cwd, 5)
    add_repo_segment(p, cwd)
    add_root_indicator(p, sys.argv[1] if len(sys.argv) > 1 else 0)
    sys.stdout.write(p.draw())

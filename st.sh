#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command \
    | grep -v Unknown.variable \
    | grep -v No.info.on.package.*found \
    | grep -v Variable.*is.never.read \
    | grep -v Unknown.subcommand..home..to..file \
    | grep -v Suspicious.variable.name...my.varname \
    | grep -v Found.constant.*which.is.also.a.variable
clc -s -l tcl
str s
git st

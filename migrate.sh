#!/bin/bash

#   Author:     Ulrich Block <ulrich.block@easy-wi.com>
#
#   This file is part of Easy-WI.
#
#   Easy-WI is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Easy-WI is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Easy-WI.  If not, see <http://www.gnu.org/licenses/>.
#
#   Diese Datei ist Teil von Easy-WI.
#
#   Easy-WI ist Freie Software: Sie koennen es unter den Bedingungen
#   der GNU General Public License, wie von der Free Software Foundation,
#   Version 3 der Lizenz oder (nach Ihrer Wahl) jeder spaeteren
#   veroeffentlichten Version, weiterverbreiten und/oder modifizieren.
#
#   Easy-WI wird in der Hoffnung, dass es nuetzlich sein wird, aber
#   OHNE JEDE GEWAEHELEISTUNG, bereitgestellt; sogar ohne die implizite
#   Gewaehrleistung der MARKTFAEHIGKEIT oder EIGNUNG FUER EINEN BESTIMMTEN ZWECK.
#   Siehe die GNU General Public License fuer weitere Details.
#
#   Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
#   Programm erhalten haben. Wenn nicht, siehe <http://www.gnu.org/licenses/>.
#
############################################

# We need to be root to migrate
if [ "`id -u`" != "0" ]; then
    echo "Change to root account required"
    su -
fi

if [ "`id -u`" != "0" ]; then
    echo "Still not root, aborting"
    exit 0
fi

# Ensure that /bin/false can be used for game server users
if [ ! -f /bin/false ]; then
    echo "Adding shell /bin/false"
    touch /bin/false
fi

if [ "`grep '/bin/false' /etc/shells`" == "" ]; then
    echo "Adding shell /bin/false to the list of valid shells"
    echo "/bin/false" >> /etc/shells
fi

# Change the clean up cronjob
if [ "`grep '/home/\*/server/\*/\*/' /etc/crontab`" != "" ]; then

    echo "Creating backup of /etc/crontab"
    cp /etc/crontab /etc/crontab.pre_migration.backup

    echo "Changing entry '/home/*/server/*/*/' at /etc/crontab to '/home/*/server/*/'"
    sed -i 's/home\/\*\/server\/\*\/\*\//home\/\*\/server\/\*\//g' /etc/crontab

    echo "Restart cron so changes are applied"
    /etc/init.d/cron restart
fi

# Check if proftpd rules are installed
if [ -f /etc/proftpd/conf.d/easy-wi.conf -a "`grep '~/\*/\*/>' /etc/proftpd/conf.d/easy-wi.conf`" != "" ]; then

    echo "Creating backup of /etc/proftpd/conf.d/easy-wi.conf"
    cp /etc/proftpd/conf.d/easy-wi.conf /etc/proftpd/easy-wi.conf.pre_migration.backup

    # For each rule, check if still exist and migrate
    echo "Changing entries at /etc/proftpd/conf.d/easy-wi.conf"

    if [ "`grep '~/\*/\*/>' /etc/proftpd/conf.d/easy-wi.conf`" != "" ]; then
        echo "Changing entry '~/*/*/>' to '~/*/>'"
        sed -i 's/~\/\*\/\*\/>/~\/\*\/>/g' /etc/proftpd/conf.d/easy-wi.conf
    fi

    if [ "`grep '/home/\*/pserver/\*>' /etc/proftpd/conf.d/easy-wi.conf`" != "" ]; then
        echo "Changing entry '/home/*/pserver/*>' to '/home/*/pserver>'"
        sed -i 's/\/home\/\*\/pserver\/\*>/\/home\/\*\/pserver>/g' /etc/proftpd/conf.d/easy-wi.conf
    fi

    if [ "`grep '<Directory ~/server/\*/' /etc/proftpd/conf.d/easy-wi.conf`" != "" ]; then
        echo "Changing entries '<Directory ~/server/*/' to '<Directory ~/server/'"
        sed -i 's/<Directory ~\/server\/\*\//<Directory ~\/server\//g' /etc/proftpd/conf.d/easy-wi.conf
    fi

    if [ "`grep '~/\*/\*/\*/\*/' /etc/proftpd/conf.d/easy-wi.conf`" != "" ]; then
        echo "Changing entries '~/*/*/*/*/' to '~/*/*/'"
        sed -i 's/~\/\*\/\*\/\*\/\*\//~\/\*\/\*\//g' /etc/proftpd/conf.d/easy-wi.conf
    fi

    /etc/init.d/proftpd restart
fi

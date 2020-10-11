# dockerify.coffee
# Copyright 2020 Patrick Meade
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------------------

BYOND_DOWNLOAD_URL = process.env.BYOND_DOWNLOAD_URL || "https://secure.byond.com/download/build/LATEST/"

BYOND_LINUX_RE = /(\d{3})\.(\d{4})_byond_linux\.zip/g
BYOND_MAJOR_MINOR_RE = /(\d{3})\.(\d{4})_byond_linux\.zip/

_ = require "lodash"
{exec} = require "child_process"
got = require "got"

exec_cmd = (cmd) ->
    return new Promise (resolve, reject) ->
        exec cmd, (err, stdout, stderr) ->
            OBJ = {err:err, stdout:stdout, stderr:stderr}
            return reject OBJ if err?
            resolve OBJ

do ->
    # get the list of the latest BYOND versions
    {body} = await got BYOND_DOWNLOAD_URL
    byond_zips = _.uniq body.match BYOND_LINUX_RE

    # for each unique version that we discovered
    for byond_zip in byond_zips
        # determine the major and minor versions
        version = byond_zip.match BYOND_MAJOR_MINOR_RE
        major = version[1]
        minor = version[2]

        # attempt to pull the image down from Docker Hub
        console.log "Pulling scorpiostation/byond:#{major}.#{minor} ..."
        try
            # if we're able to pull the image successfully, we don't need to rebuild it
            await exec_cmd "docker pull scorpiostation/byond:#{major}.#{minor}"
            continue
        catch e
            # otherwise, we do need to build it
            console.log "Building byond:#{major}.#{minor} ..."

        # build the BYOND image using our Dockerfile
        try
            await exec_cmd "docker build --build-arg MAJOR=#{major} --build-arg MINOR=#{minor} --file Dockerfile --no-cache --tag byond:#{major}.#{minor} ."
        catch e
            console.log "Error while building byond:#{major}.#{minor}"
            console.log "stdout: #{e.stdout}"
            console.log "stderr: #{e.stderr}"
            process.exit 1

        # push the image up to Docker Hub
        console.log "Pushing scorpiostation/byond:#{major}.#{minor} ..."
        try
            await exec_cmd "docker image tag byond:#{major}.#{minor} scorpiostation/byond:#{major}.#{minor}"
            await exec_cmd "docker push scorpiostation/byond:#{major}.#{minor}"
        catch e
            console.log "Error while pushing scorpiostation/byond:#{major}.#{minor}"
            console.log "stdout: #{e.stdout}"
            console.log "stderr: #{e.stderr}"
            process.exit 1

        # tag the image as the "latest" and push that tag
        console.log "Pushing scorpiostation/byond:latest ..."
        try
            await exec_cmd "docker image tag scorpiostation/byond:#{major}.#{minor} scorpiostation/byond:latest"
            await exec_cmd "docker push scorpiostation/byond:latest"
        catch e
            console.log "Error while pushing scorpiostation/byond:latest"
            console.log "stdout: #{e.stdout}"
            console.log "stderr: #{e.stderr}"
            process.exit 1

    # inform the user that we're done
    console.log "All of the latest BYOND images are built."

#----------------------------------------------------------------------------
# end of dockerify.coffee

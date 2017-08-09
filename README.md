# Automatically rip audio CDs
Config and scripts for automatically ripping audio CDs.

These scripts were assembled on a Raspberry Pi Zero W in 2017.

Once installed, they're designed to recognize when a CD is inserted
and subsequently rip the audio CD. After ripping the CD, the scripts
copy the files to Dropbox and trigger a Zapier webhook. You can easily
edit the scripts to run whatever you want when the ripping is complete.

I will happily accept pull requests for changes and improvements and appreciate
any input and suggestions. I'm not planning to build this beyond my personal
needs but I hope it will be a useful resource for other people with similar
goals.

### Components
1. `/etc/udev/rules.d/99-cd-audio-processing.rules` This script tells *udev* what to do when a disc is inserted into the CD drive
(`sr0` here). This rule tells *udev* to run a *systemd* service. We have to use
a service instead of running the script directly because *udev* kills long
running scripts.

   Call `udevadm control --reload` to force *udev* to load this rule for the drive
 without a reboot.

2. `/etc/systemd/system/rip-audio-cd@service` This just wraps the actual CD
ripping script in a *systemd* service.

3. `/usr/local/sbin/rip-audio-cd.sh` This script handles ripping and ejecting
the CD, and prevents the script from running multiple times if there are
multiple events. (I don't know if the locking is necessary with the *udev*
setup. It's something I found in tutorials and kept.)

   The real work is being done by *abcde*, a command line ripping program. The
 script redirects the log and errors to `/var/log/cdrip.log`. If *abcde* throws
 an error, this script makes sure to call *eject*.

4. `/etc/abcde.conf` This is the configuration file for *abcde*. You can pass
in flags but it's better (and standard) to set things up here. My configuration
is set to rip files and encode them as both flac and mp3. It then puts the
encoded files in `/srv/ripped-music/flac` and `/srv/ripped-music/mp3`.

   The `post_encode()` function sets up the rest of the work. It logs the artist
 and album name in `/srv/ripped-music/last-rip.log` for use by the remaining
 scripts, and then it runs the scripts.

5. `/usr/local/bin/upload-to-dropbox.sh` This script uses the Dropbox REST API
and `curl` to add the files to Dropbox. (You may need to `apt-get install
curl`.)

   You'll need a Dropbox *bearer token* for authentication. I created a Dropbox
 API app for myself (which only has access to its own folder in Dropbox), and
 then copied the bearer token from the API website. Just replace the
 `**DROPBOX_BEARER_TOKEN**` in the script with your actual token.

6. `/usr/local/bin/add-to-airtable.sh` This script would be more aptly named
`trigger-zapier.sh`. It posts the artist and album as a JSON object to a Zapier
webhook. The webhook is setup to add a row to an AirTable table. (Another
Zapier trigger sends me an email when that new row is added.)

   You can create a new webhook trigger on the Zapier website. Just replace the
 `**ZAPIER_WEBHOOK**` in the script with the url for the webhook.


### Installing
1. You'll need to install *abcde* and *eject*. You can use `sudo apt-get -y install
abcde eject`. If you're encoding to flac and mp3 you'll also want to install
*lame* and *flac*.

2. If you're testing this stuff while logged in (i.e., if you're running *abcde*
or *eject* from the command line, you may need to add yourself to the `cdrom`
group. *eject* didn't work for me without `sudo` otherwise. `useradd -G cdrom
$USERNAME`

3. You might need to create the `/srv/ripped-music` directory where the files
are saved, and you'll want to give permissions to the `cdrom` group so that
you can write the files if you call *abcde* manually.

4. At this point, just copy the files to their respective places in the
filesystem. That should be it.

### Issues
#### Ripping Errors
Here's how I diagnose:

1. Check the log file `/var/log/cdrip.log`

2. Check the *abcde* `status` and `errors` files.

   *abcde* creates a temp folder in the root directory, `/abcde.???`
 (where `???` is just to say that whatever follows the `.` is random). Usually
 that directory will contain a `status` file and sometimes an `errors` file with
 details.

   Sometimes *cdparanoia*, which *abcde* uses to rip the audio, throws errors
when reading, which shuts down the whole script. I've had this happen on perfect,
just opened CDs. I'm not sure how to fix this. Sometimes you can just put the
CD back in and *abcde* will pick up where it left off. Some CDs just seem like
they can't move forward.

#### Auto-run Errors
Sometimes the scripts don't run on insertion. Here's what I do:

1. `eject` the CD and put it back in.
2. Check the status of the *systemd* service with `systemctl status rip-audio-cd@sr0.service`
3. Restart the service with `sudo systemctl restart rip-audio-cd@sr0.service`

#### Tagging / CDDB Errors
Some CDs haven't been found by the CDDB lookups. Not sure what to do with this yet. The script
just rips them as Unknown Artist and Unknown Album and Track 1-N.

#### Double Albums
This depends a bit on what's in the CDDB database. If both discs have the same
album name, the files will get ripped to the same directory but both discs'
tracks will be numbered starting at 1. Right now I'll probably fix it manually
but an automated solution would be lovely.

#### General Linux Stuff
I put files a) where they worked and b) where they made sense based on what I
could find on the web. I think in general all of these directories are
appropriate, but I wouldn't be surprised if there are better places to put them.

# Docker dumpvdl2

![Banner](https://github.com/sdr-enthusiasts/docker-acarshub/blob/16ab3757986deb7c93c08f5c7e3752f54a19629c/Logo-Sources/ACARS%20Hub.png "banner")
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/fredclausen/docker-acarshub/Deploy%20to%20Docker%20Hub)](https://github.com/sdr-enthusiasts/docker-acarshub/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/fredclausen/acarshub.svg)](https://hub.docker.com/r/fredclausen/acarshub)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/fredclausen/acarshub/latest)](https://hub.docker.com/r/fredclausen/acarshub)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container for running [dumpvdl2](https://github.com/szpajder/dumpvdl2) and forwarding the received JSON messages to another system or docker container. Best used alongside [ACARS Hub](https://github.com/sdr-enthusiasts/docker-acarshub).

Builds and runs on `amd64`, `arm64`.

Please note: **DUE TO LIBSDRPLAY, THIS CONTAINER WILL NOT RUN ON ARM32 DEVICES**

## Required hardware

A computer host on a suitable architecture and one USB RTL-SDR dongle connected to an antenna.

## Deprecation Notice

`SERIAL` has been deprecated in favor of `SOAPYSDR`. Please update your configuration accordingly. If `SERIAL` is set the driver will be set to `rtlsdr` and the serial number will be set to the value of `SERIAL`.

## Up and running

```yaml
version: "2.0"

services:
  dumpvdl2:
    image: ghcr.io/sdr-enthusiasts/docker-dumpvdl2:latest
    container_name: dumpvdl2
    restart: always
    ports:
    environment:
      - TZ="America/Denver"
      - SOAPYSDR=driver=rtlsdr,serial=13305
      - FEED_ID=VDLM
      - FREQUENCIES=136725000;136975000;136875000
      - ZMQ_MODE=server
      - ZMQ_ENDPOINT=tcp://0.0.0.0:45555
    tmpfs:
      - /run:exec,size=64M
      - /var/log
    device_cgroup_rules:
      - 'c 189:* rwm'
    volumes:
      - /dev/bus/usb:/dev/bus/usb:ro
```

## Configuration options

| Variable             | Description                                                                                                                                                                                      | Required | Default                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | -------------------------------------------------------------- |
| `TZ`                 | Your timezone                                                                                                                                                                                    | No       | UTC                                                            |
| `SOAPYSDR`           | The SoapySDR device string that identifies your dongle. See below for supported soapy sdr types.                                                                                                 | No       | Blank                                                          |
| `SOAPY_DEVICE_SETTINGS` | The SoapySDR settings string with comma separated options, example: biastee=true                                                                                                 | No       | Blank                                                          |
| `FEED_ID`            | Used by the decoder to insert a unique ID in to the output message                                                                                                                               | Yes      | Blank                                                          |
| `FREQUENCIES`        | Semicolon-separated list of frequencies for the decoder to listen to. All frequencies should either be in Hz, or in MHz with exactly 3 digits after the decimal point.                           | Yes      | Blank                                                          |
| `PPM`                | Parts per million correction of the decoder                                                                                                                                                      | No       | 0                                                              |
| `GAIN`               | The gain applied to the RTL-SDR dongle.                                                                                                                                                          | No       | `40`                                                           |
| `OVERSAMPLE`         | Overrides the default oversampling rate used by dumpvdl2.                                                                                                                                        | No       | Blank                                                          |
| `VDLM_FILTER_ENABLE` | Filter out non-informational messages. Turning this off (set to a blank value) will cause increased message rate but the messages will be of little value. Will cause extra SD card read/writes. | No       | `TRUE`                                                         |
| `VDLM_FILTER`        | Specify the dumpvdl2 filter string. Used it `VDLM_FILTER_ENABLE` is true.                                                                                                                        | No       | `all,-avlc_s,-acars_nodata,-x25_control,-idrp_keepalive,-esis` |
| `QUIET_LOGS`         | Mute log output to the bare minimum. Set to `false` to disable.                                                                                                                                  | No       | `TRUE`                                                         |
| `ZMQ_MODE`           | Output to [zmq](https://zeromq.org) publisher socket. This sets the mode to `client` or `server`.                                                                                                | No       |                                                                |
| `ZMQ_ENDPOINT`       | Output to [zmq](https://zeromq.org) publisher socket. This sets the `endpoint`. Syntax is `tcp://address:port`                                                                                   | No       |                                                                |
| `STATSD_SERVER`      | Output to a statsd instance.                                                                                                                                                                     | No       | `unset`                                                        |

## SoapySDR device string

The SoapySDR device string is used to identify your RTL-SDR dongle. The default value is `driver=rtlsdr` which is suitable for most users. If you are using a different SDR, you will need to provide the correct device string. For example, if you are using an Airspy Mini, you would set `SOAPYSDR=driver=airspy`. Pass any additional options for the SDR in via this option as well.

Supported Soapy Drivers:

- `rtlsdr`
- `rtltcp`
- `airspy`
- `sdrplay`

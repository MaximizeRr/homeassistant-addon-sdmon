# Home Assistant Add-on Repository: SD Card Monitor

![Project Maintenance][maintenance-shield]
[![License][license-shield]](LICENSE)

## About

This repository contains a Home Assistant add-on for monitoring industrial SD card health using [sdmon](https://github.com/Ognian/sdmon).

## Add-ons

This repository contains the following add-on:

### [SD Card Monitor (sdmon)](./sdmon)

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

Monitor the health status of industrial-grade SD cards directly from Home Assistant. Supports Apacer, Kingston, SanDisk, and Western Digital industrial SD cards.

## Installation

To use this add-on repository, add the following URL to your Home Assistant add-on store:

```
https://github.com/maximizerr/homeassistant-addon-sdmon
```

### Adding the Repository

1. Open your Home Assistant instance
2. Navigate to **Supervisor** → **Add-on Store**
3. Click the **⋮** menu in the top right
4. Select **Repositories**
5. Add this repository URL
6. Click **Add**

The add-on will now appear in your add-on store.

## Add-ons Provided

- **SD Card Monitor (sdmon)** - Monitor industrial SD card health status

## Support

For issues and questions:

- [Open an issue on GitHub][issues]
- Check the [sdmon documentation][sdmon]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

The sdmon software is also licensed under GPL-2.0, Copyright (c) 2018 - today, OGI-IT, Ognian Tschakalov and contributors.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[issues]: https://github.com/maximizerr/homeassistant-addon-sdmon/issues
[license-shield]: https://img.shields.io/github/license/maximizerr/homeassistant-addon-sdmon.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2025.svg
[sdmon]: https://github.com/Ognian/sdmon

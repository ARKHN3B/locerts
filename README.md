# Locerts - Local Certificates Generator

[![GitHub license](https://img.shields.io/badge/license-MIT-blue)](./LICENSE.txt)

This GitHub project give you a utility script that generates local certifications for your computer.

The script is written in Bash, and it uses OpenSSL to generate the certificates.

The script takes in a few inputs from a config.yml file.

Once the inputs are provided, the script generates the certificate files and stores them in a designated directory on your computer. The user can then use these certificates for various purposes, such as securing local web applications or testing local SSL/TLS connections.

The project includes detailed documentation on how to use the script, along with examples and troubleshooting tips. It also includes a license and a contribution guide for other developers who may want to contribute to the project.

#### Important notes
1. This script works only on macOS for the moment. Come and contribute to make this script available for Linux and Windows 🤗.
2. This script is not intended to be used in production. It is only intended to be used for local development purposes.
3. This script doesn't work for multiple domains. Come and contribute to make this script available for multiple domains 🤗.



## To do
- [ ] Make the script available for Linux
- [ ] Make the script available for Windows
- [ ] Add logic for multiple domains in the config.yml file (array) and in the script (for loop)


## Documentation

To use this script, nothing could be easier.

You just have to fill in the fields (at least mandatory) in the `config.yml` file and run the script with the command `sh ./generate.sh`.



#### API
Mandatory fields
- **common_name**: the common name of the certificate *(e.g. Might Tower)*
- **dest**: the path to the directory where the certificates will be stored *(e.g. ./ssl)*
- **domain**: the domain name of the certificate *(e.g. mighttower.local)*

Optional fields
- **options**
  - **days**: automatically set to ***1850 days*** by default (5 year certificate)
  - **details**
    - **country_name**: the ***country name*** of the certificate (2 letters, default: JP)
    - **state_or_province_name**: the ***state or province name*** of the certificate (default: Tokyo)
    - **locality_name**: the ***locality name*** of the certificate (default: Tokyo)
    - **organization_name**: the ***organization name*** of the certificate (default: Might Tower)
    - **organizational_unit_name**: the ***organizational unit name*** of the certificate (default: Heroes Department)
  - **subdomain_wildcard**: Useful ***boolean*** for multi-tenant apps or apps with subdomains *(default: false)*
## License

[MIT](./LICENSE.txt)


## Authors

- [Ben Lmsc](https://www.github.com/arkhn3b)


## Contributing

Contributions are always welcome!

See `contributing.md` for ways to get started.

Please adhere to this project's `code of conduct`.


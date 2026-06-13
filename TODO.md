# Purpose

The purpose of this project is to automate the retrieval of invoices from different providers, such as Telekom, utilities, and bank statements. This will enable users to collect their documents locally without the need for manual downloads.

As much as we can we want to follow convention over configuration as a mindset.

# Research

See if a similar project exists that we can use as a starting point.

# Implementation

- Ruby stack
- SBE/TDD with automated testing
- pipeline that ensure compatibility with Linux/Mac OS X/Windows
  - GoCD for the local cbp-org development environment
  - GitHub Actions for the remote repository
- RCov
- Contract Testing / Integration Testing noting there is not going to be any test environment from the providers: we have to be extra careful to not cause security issues/rejections...

# implement the automated retrieval of invoices (telekom, utilities, bank statements).

- [ ] Implement automated retrieval of invoices from Telekom
- [ ] Implement automated retrieval of invoices from utilities
- [ ] Implement automated retrieval of bank statements

- [ ] Implement automated retrieval of invoices from other providers

# Should keep track about what was downloaded or not (w/ option to redownload already, if needed)

- [ ] Implement tracking of downloaded invoices
- [ ] Implement option to redownload already downloaded invoices

# Document validity should be checked

# procedure to be scheduled to run on a monthly basis

- [ ] Implement procedure to run on a monthly basis



# access should be secure and deal with special authentication means

- [ ] Implement secure access with special authentication means




# How to Contribute

stage1-xen is [Apache 2.0 licensed](LICENSE) and accepts contributions
via emails on the xen-devel mailing list as well as GitHub pull
requests. This document outlines some of the conventions on development
workflow, commit message formatting, contact points and other resources
to make it easier to get your contribution accepted.

### Certificate of Origin

By contributing to this project you agree to the Developer Certificate of
Origin (DCO). This document was created by the Linux Kernel community and is a
simple statement that you, as a contributor, have the legal right to make the
contribution. See the [DCO](DCO) file for details.

### Mailing List

Please use xen-devel@lists.xen.org for questions and patches, CCing the
relevant maintainers, see [MAINTAINERS](MAINTAINERS). Make sure to add
"stage1-xen" to the email subject.

Use the git format-patch and git send-email commands to generate the
patches and send them to the mailing list.

### Github

This is a rough outline of what a contributor's workflow looks like:

- Create a topic branch from where you want to base your work (usually master).
- Make commits of logical units.
- Make sure your commit messages are in the proper format (see below).
- Push your changes to a topic branch in your fork of the repository.
- Make sure the [tests](tests/README.md#manually-running-the-tests) pass, and add any new tests as appropriate.
- Submit a pull request to the original repository.
- Submit a comment with the sole content "@reviewer PTAL" (please take a look) in GitHub
  and replace "@reviewer" with the correct recipient.
- When addressing pull request review comments add new commits to the existing pull request or,
  if the added commits are about the same size as the previous commits,
  squash them into the existing commits.
- Once your PR is labelled as "reviewed/lgtm" squash the addressed commits in one commit.
- If your PR addresses multiple subsystems reorganize your PR and create multiple commits per subsystem.
- Your contribution is ready to be merged.

Thanks for your contributions!


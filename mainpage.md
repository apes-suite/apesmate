project: APESmate
summary: A coupling tool within the APES suite.
src_dir: source/
src_dir: build/ford
exclude_dir: build/ford/treelm
exclude_dir: build/ford/plugins
external: https://geb.sts.nt.uni-siegen.de/doxy/aotus/
external: https://geb.sts.nt.uni-siegen.de/doxy/treelm/
output_dir: docu
media_dir: treelm/media
graph: true
graph_maxdepth: 4
graph_maxnodes: 32
display: public
display: protected
display: private
sort: permission
source: false
author: University of Siegen
title: Mainpage
print_creation_date: True
md_extensions: markdown.extensions.toc

# Introduction to APESmate

This tool provides a coupling mechanism for APES solvers to interact with each
other.
It utilizes the variables system from Treelm to provide access to values from
other domains.
These values can be used like other variables in the configuration, for example
as boundary conditions (surface coupling) or as source terms (volume coupling).
APESmate includes the solvers in its executable and takes care of steering them.
In the configuration the computational load for each domain needs to be provided
to allow a balanced distribution on parallel systems.
Each domain has to have its own, separate configuration to describe the setup
in each solver.

## Downloading APESmate

We use Mercurial (hg), an open source distributed version control system,
for the APES projects.
To obtain the sources of APESmate, you need to have Mercurial available.
It may be downloaded from the
[official website](https://www.mercurial-scm.org)
or already available through some packaging system for your machine.
A nice introduction on the usage of Mercurial is available at
[hginit](http://hginit.com).
APESmate can be cloned from the following repository at
`https://geb.sts.nt.uni-siegen.de/hg/apesmate` by typing the following command:

```bash
hg clone https://geb.sts.nt.uni-siegen.de/hg/apesmate
```

in your console.
This also will get you the APESmate repository TreElm
as a subrepository in the directory `apesmate`.
Note that you need to get other supporting tools from the APES framework
or the complete framework itself to make use
of other solvers for your simulations.

To get more information about APESmate and how to use it,
please take a look at [Documentation](page/index.html).

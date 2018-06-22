<!-- README.md is generated from README.Rmd. Please edit that file -->
PRISM
=====

[![Build
Status](https://travis-ci.org/rcannood/PRISM.svg?branch=master)](https://travis-ci.org/rcannood/PRISM)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/rcannood/PRISM?branch=master&svg=true)](https://ci.appveyor.com/project/rcannood/PRISM)
[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/PRISM)](https://cran.r-project.org/package=PRISM)
[![Coverage
Status](https://codecov.io/gh/rcannood/PRISM/branch/master/graph/badge.svg)](https://codecov.io/gh/rcannood/PRISM?branch=master)

PRISM provides the `qsub_lapply` function, which helps you parallellise
lapply calls to gridengine clusters.

Usage
-----

After installation and configuration of the PRISM package, running a job
on a cluster supporting gridengine is as easy as:

    library(PRISM)
    qsub_lapply(1:3, function(i) i + 1)

    ## [[1]]
    ## [1] 2
    ## 
    ## [[2]]
    ## [1] 3
    ## 
    ## [[3]]
    ## [1] 4

Installation
------------

On unix-based systems, you will first have to install libssh.

-   deb: `apt-get install libssh-dev` (Debian, Ubuntu, etc)
-   rpm: `dnf install libssh-devel` (Fedora, EPEL) (if `dnf` is not
    install, try `yum`)
-   brew: `brew install libssh` (OSX)

You can install PRISM with devtools as follows:

    devtools::install_github("rcannood/PRISM")

Initial test
------------

For the remainder of this README, we will assume you have an account
called `myuser` on a cluster located at `mycluster.address.org`
listening on port `1234`. This cluster is henceforth called the
'remote'. You will require a local folder to store temporary data in
(e.g. `/tmp/r2gridengine`), and a remote folder to store temporary data
in (e.g. `/scratch/personal/myuser/r2gridengine`).

After installation of the PRISM package, first try out whether you can
connect to this server. If you have not yet [set up an SSH
key](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)
and uploaded it to the remote, you will be asked for password.

    qsub_config <- create_qsub_config(
      remote = "myuser@mycluster.address.org:1234",
      local_tmp_path = "/tmp/r2gridengine",
      remote_tmp_path = "/scratch/personal/myuser/r2gridengine"
    )

    qsub_lapply(1:3, function(i) i + 1, qsub_config = qsub_config) 

Permanent configuration
-----------------------

If the previous section worked just fine, you can for a permanent
configuration of the qsub config as follows:

    set_default_qsub_config(qsub_config, permanent = TRUE)

If you were asked for a password in the previous step, it would be
useful to [set up an SSH
key](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)
and uploaded it to the remote.

Customisation of individual runs
--------------------------------

Some tasks will require you to finetune the qsub config, for example
because they require more walltime or memory than allowed by default.
These can also be specified using the `create_qsub_config` command, or
using `override_qsub_config` if you have already created a default qsub
config. Check `?override_qsub_config` for a detailed explanation of each
of the possible parameters.

    qsub_lapply(
      X = 1:3,
      FUN = function(i) {
        # simulate a very long calculation time
        # this might annoy other users of the cluster, 
        # but sometimes there is no way around it
        Sys.sleep(sample.int(3600, 1))
        i + 1
      },
      qsub_config = override_qsub_config(
        name = "MyJob", # this name will show up in qstat
        mc_cores = 2, # the number of cores to allocate per element in X
        memory = "10G", # memory per core per task
        max_wall_time = "12:00:00" # allow each task to run for 12h
      )
    )

Asynchronous jobs
-----------------

In almost every case, it is most practical to run jobs asynchronously.
This allows you to start up a job, save the meta data, come back later,
and fetch the results from the cluster. This can be done by changing the
`wait` parameter.

    qsub_async <- qsub_lapply(
      X = 1:3,
      FUN = function(i) {
        Sys.sleep(10)
        i + 1
      },
      qsub_config = override_qsub_config(
        wait = FALSE
      )
    )

    readr::write_rds(qsub_async, "temp_file.rds")

    # you can restart your computer / R session after having saved the `qsub_async` object somewhere.
    qsub_async <- readr::read_rds("temp_file.rds")

    # if the job has finished running, this will retrieve the output
    qsub_retrieve(qsub_async)

Specify which objects gets transferred
--------------------------------------

By default, `qsub_lapply` will transfer all objects in your current
environment to the cluster. This might result in long waiting times if
the current environment is very large. You can define which objects get
transferred to the cluster as follows:

    j <- 1
    k <- rep(10, 1000000000) # 7.5 Gb
    qsub_lapply(
      X = 1:3,
      FUN = function(i) {
        i + j
      },
      qsub_environment = "j"
    )

Oh no, something went wrong
---------------------------

Inevitably, something will go break. PRISM will try to help you by
reading out the log files if no output was produced.

    qsub_lapply(
      X = 1:3,
      FUN = function(i) {
        if (i == 2) stop("Something went wrong!")
        i + 1
      }
    )

    ## Error in FUN(X[[i]], ...): File: /home/rcannood/Workspace/.r2gridengine/20180622_070421_R2PRISM_q7BpVahOe6/log/log.2.e.txt
    ## by .GlobalEnv when processing object ‘’
    ## Error in (function (i)  : Something went wrong!
    ## Calls: with ... with.default -> eval -> eval -> do.call -> <Anonymous>
    ## Execution halted

Alternatively, you might anticipate possible errors but still be
interested in the rest of the output. In this case, the error will be
returned as an attribute.

    qsub_lapply(
      X = 1:3,
      FUN = function(i) {
        if (i == 2) stop("Something went wrong!")
        i + 1
      },
      qsub_config = override_qsub_config(
        stop_on_error = FALSE
      )
    )

    ## [[1]]
    ## [1] 2
    ## 
    ## [[2]]
    ## [1] NA
    ## attr(,"qsub_error")
    ## [1] "File: /home/rcannood/Workspace/.r2gridengine/20180622_070428_R2PRISM_EiIsczBl6Q/log/log.2.e.txt\nby .GlobalEnv when processing object ‘’\nError in (function (i)  : Something went wrong!\nCalls: with ... with.default -> eval -> eval -> do.call -> <Anonymous>\nExecution halted\n"
    ## 
    ## [[3]]
    ## [1] 4

If all help prevails, you can try to manually debug the session by not
removing the temporary files at the end of an execution by setting
`remove_tmp_folder` to `FALSE`, logging into the remote server, going to
the temporary folder located at
`get_default_qsub_config()$remote_tmp_path`, and executing `script.R`
line by line in R, by hand.

    qsub_lapply(
      X = 1:3,
      FUN = function(i) {
        if (i == 2) stop("Something went wrong!")
        i + 1
      },
      qsub_config = override_qsub_config(
        remove_tmp_folder = FALSE
      )
    )

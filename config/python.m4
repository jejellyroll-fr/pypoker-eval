## ------------------------                                 -*- Autoconf -*-
## Python file handling
## From Andrew Dalke
## Updated by James Henstridge
## Updated by Ludovic Heyberger (2005), Loic Dachary (2006)
## ------------------------
# Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005
# Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# AM_PATH_PYTHON([VERSION-CONSTRAINT], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ---------------------------------------------------------------------------
# Adds support for distributing Python modules and packages.  To
# install modules, copy them to $(pythondir), using the python_PYTHON
# automake variable.  To install a package with the same name as the
# automake package, install to $(pkgpythondir), or use the
# pkgpython_PYTHON automake variable.
#
# The variables $(pyexecdir) and $(pkgpyexecdir) are provided as
# locations to install python extension modules (shared libraries).
# Another macro is required to find the appropriate flags to compile
# extension modules.
#
# If your package is configured with a different prefix to python,
# users will have to add the install directory to the PYTHONPATH
# environment variable, or create a .pth file (see the python
# documentation for details).
#
# If the VERSION-CONSTRAINT argument is passed, AM_PATH_PYTHON will
# cause an error if the version of python installed on the system
# doesn't meet the requirement. VERSION-CONSTRAINT should consist of
# an operator (>=, <=, =, >, <) followed by a version (1, 2, 2.3, 2.4, 1.5.2 etc.)
# Examples: >2.3, =2.2, >=1.5.1 ... If the operator is omited, it defaults
# to >= (i.e. 2.3 is equivalent to >=2.3)
AC_DEFUN([AM_PATH_PYTHON],
 [
  dnl Find a Python interpreter.  Python versions prior to 1.5 are not
  dnl supported because the default installation locations changed from
  dnl $prefix/lib/site-python in 1.4 to $prefix/lib/python1.5/site-packages
  dnl in 1.5.
  m4_define_default([_AM_PYTHON_INTERPRETER_LIST],
                      [python python2 python3.11 python3.8 python2.5 python2.4 python2.3 python2.2 dnl
python2.1 python2.0 python1.6 python1.5])

  m4_if([$1],[],[
    dnl No version check is needed.
    # Find any Python interpreter.
    if test -z "$PYTHON"; then
      AC_PATH_PROGS([PYTHON], _AM_PYTHON_INTERPRETER_LIST, :)
    fi
    am_display_PYTHON=python
  ], [
    if expr "$1" : "[[<>=]]" > /dev/null ; then
      required_version="$1"
    elif test -z "$1" || expr "$1" : '[ 	]*$' > /dev/null ; then
      required_version=""
    else
      required_version=">=$1"
    fi
    dnl A version check is needed.
    if test -n "$PYTHON"; then
      # If the user set $PYTHON, use it and don't search something else.
      AC_MSG_CHECKING([whether $PYTHON version $required_version])
      AM_PYTHON_CHECK_VERSION([$PYTHON], [$required_version],
			      [AC_MSG_RESULT(yes)],
			      [AC_MSG_ERROR(too old)])
      am_display_PYTHON=$PYTHON
    else
      # Otherwise, try each interpreter until we find one that satisfies
      # VERSION.
      AC_MSG_CHECKING([for a Python interpreter with version $required_version])
      for am_cv_pathless_PYTHON in _AM_PYTHON_INTERPRETER_LIST none; do
	  test "$am_cv_pathless_PYTHON" = none && break
	  AM_PYTHON_CHECK_VERSION([$am_cv_pathless_PYTHON], [$required_version], [break])
      done
      AC_MSG_RESULT([done])
      # Set $PYTHON to the absolute path of $am_cv_pathless_PYTHON.
      if test "$am_cv_pathless_PYTHON" = none; then
	PYTHON=:
      else
        unset ac_cv_path_PYTHON
        AC_PATH_PROG([PYTHON], [$am_cv_pathless_PYTHON])
      fi
      am_display_PYTHON=$am_cv_pathless_PYTHON
    fi
  ])

  if test "$PYTHON" = :; then
  dnl Run any user-specified action, or abort.
    m4_default([$3], [AC_MSG_ERROR([no suitable Python interpreter found for $1])])
  else

  dnl Query Python for its version number.  Getting [:3] seems to be
  dnl the best way to do this; it's what "site.py" does in the standard
  dnl library.

  AC_MSG_CHECKING([for $am_display_PYTHON version])
  am_cv_python_version=`$PYTHON -c "import sys; print (sys.version[[:3]])"`
  AC_MSG_RESULT([done])
  AC_SUBST([PYTHON_VERSION], [$am_cv_python_version])

  dnl Use the values of $prefix and $exec_prefix for the corresponding
  dnl values of PYTHON_PREFIX and PYTHON_EXEC_PREFIX.  These are made
  dnl distinct variables so they can be overridden if need be.  However,
  dnl general consensus is that you shouldn't need this ability.

  AC_SUBST([PYTHON_PREFIX], ['${prefix}'])
  AC_SUBST([PYTHON_EXEC_PREFIX], ['${exec_prefix}'])

  dnl At times (like when building shared libraries) you may want
  dnl to know which OS platform Python thinks this is.

  AC_MSG_CHECKING([for $am_display_PYTHON platform])
  am_cv_python_platform=`$PYTHON -c "import sys; print (sys.platform)"`
  AC_MSG_RESULT([done])
  AC_SUBST([PYTHON_PLATFORM], [$am_cv_python_platform])


  dnl Set up 4 directories:

  dnl pythondir -- where to install python scripts.  This is the
  dnl   site-packages directory, not the python standard library
  dnl   directory like in previous automake betas.  This behavior
  dnl   is more consistent with lispdir.m4 for example.
  dnl Query distutils for this directory.  distutils does not exist in
  dnl Python 1.5, so we fall back to the hardcoded directory if it
  dnl doesn't work.
  AC_MSG_CHECKING([for $am_display_PYTHON script directory])
  am_cv_python_pythondir=`$PYTHON -c "from distutils import sysconfig; print (sysconfig.get_python_lib(0,0,prefix='$PYTHON_PREFIX'))" 2>/dev/null ||
     echo "$PYTHON_PREFIX/lib/python$PYTHON_VERSION/site-packages"`
  AC_MSG_RESULT([done])
  AC_SUBST([pythondir], [$am_cv_python_pythondir])

  dnl pkgpythondir -- $PACKAGE directory under pythondir.  Was
  dnl   PYTHON_SITE_PACKAGE in previous betas, but this naming is
  dnl   more consistent with the rest of automake.

  AC_SUBST([pkgpythondir], [\${pythondir}/$PACKAGE])

  dnl pyexecdir -- directory for installing python extension modules
  dnl   (shared libraries)
  dnl Query distutils for this directory.  distutils does not exist in
  dnl Python 1.5, so we fall back to the hardcoded directory if it
  dnl doesn't work.
  AC_MSG_CHECKING([for $am_display_PYTHON extension module directory])
  am_cv_python_pyexecdir=`$PYTHON -c "from distutils import sysconfig; print (sysconfig.get_python_lib(1,0,prefix='$PYTHON_EXEC_PREFIX'))" 2>/dev/null ||
     echo "${PYTHON_EXEC_PREFIX}/lib/python${PYTHON_VERSION}/site-packages"`
  AC_MSG_RESULT([done])
  AC_SUBST([pyexecdir], [$am_cv_python_pyexecdir])

  dnl pkgpyexecdir -- $(pyexecdir)/$(PACKAGE)

  AC_SUBST([pkgpyexecdir], [\${pyexecdir}/$PACKAGE])

  dnl Run any user-specified action.
  $2
  fi
unset am_cv_pathless_PYTHON
unset am_cv_python_version
unset am_cv_python_platform
unset am_cv_python_pythondir
unset am_cv_python_pyexecdir
])


# AM_PYTHON_CHECK_VERSION(PROG, VERSION-CONSTRAINT, [ACTION-IF-TRUE], [ACTION-IF-FALSE])
# ---------------------------------------------------------------------------
# Run ACTION-IF-TRUE if the Python interpreter PROG has version that 
# satifies VERSION-CONSTRAINT.
# Run ACTION-IF-FALSE otherwise.
# This test uses sys.hexversion instead of the string equivalent (first
# word of sys.version), in order to cope with versions such as 2.2c1.
# hexversion has been introduced in Python 1.5.2; it's probably not
# worth to support older versions (1.5.1 was released on October 31, 1998).
# Do *not* use the operator as it is not available in every supported 
# python versions
AC_DEFUN([AM_PYTHON_CHECK_VERSION],
 [prog="import sys
if '$2' == '': sys.exit(0)
spec = str.replace('$2', ' ', '')
if spec[[:2]] == '<=':
  version_string = spec[[2:]]
elif spec[[:2]] == '>=':
  version_string = spec[[2:]]
elif spec[[:1]] == '=':
  version_string = spec[[1:]]
elif spec[[:1]] == '>':
  version_string = spec[[1:]]
elif spec[[:1]] == '<':
  version_string = spec[[1:]]
ver = list(map(int, str.split(version_string, '.')))
vermap = map(int, str.split(version_string, '.'))
syshexversion = sys.hexversion >> (8 * (4 - l""en(list(ver))))
verhex = 0
for i in vermap: verhex = (verhex << 8) + i
print (('sys.hexversion = 0x%08x, verhex = 0x%08x') % (syshexversion, verhex))
if spec[[:2]] == '<=':
  status = syshexversion <= verhex
elif spec[[:2]] == '>=':
  status = syshexversion >= verhex
elif spec[[:1]] == '=':
  status = syshexversion == verhex
elif spec[[:1]] == '>':
  status = syshexversion > verhex
elif spec[[:1]] == '<':
  status = syshexversion < verhex
else:
  status = syshexversion >= verhex

if status:
  sys.exit(0)
else:
  sys.exit(1)"
  AS_IF([AM_RUN_LOG([$1 -c "$prog"])], [$3], [$4])])


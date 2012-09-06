
       Welcome to the GOSPL - Global Open Source Poplog Library

-- Introduction -------------------------------------------------------

The GOSPL is a collection of source code that is reviewed and maintained
by myself, Stephen Leach.  The contributions have been submitted
by various members of the Poplog community over the past twenty years.
It forms the bedrock of my own development environment.

GOSPL is intended to complement the huge library of functions that is
distributed with Poplog.  In particular, it provides some important
missing facilities such as a project structure (not to be confused with
the defunct pop_ui_projecttool.)  Wherever it makes sense, the
established naming and documentation conventions have been followed.  As
maintainer I modify contributions where necessary to fit with these
conventions so that the GOSPL library has a sense of unity.

All code on this website has been put into the public domain in the
interest of creating a useful public resource.  The licence is held in a
file called LICENCE.txt and is closely based on the Poplog Open Source
Licence.


-- Origin -------------------------------------------------------------

To start off with I have made an extensive rewrite of the old PLUG source
code archive.  The problem I have tried to address is how to organise such a
diverse collection of projects.  To solve this problem I have added a simple
kind of project system that allows you to select individual contributions.

In the process of bringing order to this large collection, I have
temporarily shelved material that I couldn't immediately make fit the pattern.
 As time goes on, I'll be reintroducing the material that has not been made
obsolete by the passage of time.


-- Organisation -------------------------------------------------------

The GOSPL is organised into the following sections :-

    gospl/project-collection/
        The main projects directory.  The most convenient way to browse
        this is using a web browser.  Start from the gospl/index.html
        file.

    gospl/contrib/
        Self-contained contributions that are not yet integrated with
        the projects.


-- Installation -------------------------------------------------------------

There are two main ways to install the GOSPL library, as a shared
installation that anyone on the computer can use or limited to your
own personal login.  It is difficult to provide a script for
installing GOSPL because of the wide variation in Poplog installations
but the instructions in INSTALL.txt are straightforward.

To make a personal installation, you unpack the archive into a directory
such as $poplib/gospl and then add the following lines to your
$poplib/init.p

    compile( '$poplib/gospl/init.p' );
    uses_project pop11
    uses_project ved    ;;; and any other projects you like.

However, this does not address the question of what each project contains.
The best way to get an overview of this is to browse the CONTENT.html files
that are automatically created for each project.


-- Feedback and Contributions -----------------------------------------------

I am always interested in getting your feedback on the GOSPL library
and in receiving further contributions.  My contact details are
provided at the end of this file.  Please remember that all submissions
should be accompanied by a letter granting permission to publish
under the GOSPL licence.

-----------------------------------------------------------------------------
Stephen Leach,  9th Dec 2004
Email/MSN:      steve@watchfield.com
AIM/iChat:      sfkleach@mac.com
-----------------------------------------------------------------------------

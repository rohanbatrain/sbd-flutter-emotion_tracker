2. Using pkg for Advanced Installation (Installer Package)

If you want a more traditional installer, similar to what you’d find with professional macOS applications, you can create a .pkg installer. A .pkg file is an installer package that guides the user through the installation process and places files in the appropriate directories.
Tools for Creating .pkg Files:

You can use Apple's pkgbuild and productbuild commands in the Terminal, or use third-party tools to simplify the process. Below are the steps to manually create a .pkg installer.
Steps to Create a .pkg File:
1. Prepare Your App

Ensure your app is in the correct directory structure. Typically, you will need the .app inside a folder structure like this:

MyApp/
├── MyApp.app
└── Scripts/        (optional: for pre/post install scripts)

2. Create a Directory for the Installer

Create a folder structure for the installation. For example:

mkdir -p ~/Desktop/MyInstaller/MyApp

Then, place the .app in this directory.
3. Create the pkg Using pkgbuild

Once everything is prepared, use the pkgbuild command to create a .pkg installer:

pkgbuild --identifier com.yourcompany.myapp --version 1.0 --install-location /Applications --root ~/Desktop/MyInstaller/MyApp ~/Desktop/MyApp.pkg

    --identifier: A unique identifier for your app (typically a reverse domain name style).
    --version: The version of your app.
    --install-location: The location where the app will be installed (usually /Applications for macOS apps).
    --root: The directory containing the .app file.
    The last argument is the path to where the .pkg will be saved.

4. Create a distribution Package (Optional for Advanced Customization)

If you want to include a custom installation process (like adding scripts to run before or after the installation), you can create a distribution package.

productbuild --distribution ~/Desktop/distribution.xml --package-path ~/Desktop/MyInstaller ~/Desktop/FinalInstaller.pkg

You will need to create a distribution.xml file that defines the installation steps.
5. Test the .pkg Installer

Before distributing the .pkg file, you should test it on your own machine to ensure everything works as expected.
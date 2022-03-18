#!/bin/sh -x

# It will be run with two args: buildroot spec
BUILDROOT="$1"
SPEC="$2"

PRODUCT=atom

# TODO: /usr/share/atom-beta -> /usr/lib64/atom-beta

subst '1iAutoReq:yes,nomonolib,nomono,nopython' $SPEC
subst '1iAutoProv:no' $SPEC

if [ ! -f "$BUILDROOT/usr/bin/$PRODUCT" ] ; then
    subst "s|%files|%files\n%_bindir/$PRODUCT|" $SPEC
    #ln -s $PRODUCT-beta $BUILDROOT/usr/bin/$PRODUCT
    # command name is sensitive
    echo "exec /usr/bin/$PRODUCT-beta" > $BUILDROOT/usr/bin/$PRODUCT
    chmod a+x $BUILDROOT/usr/bin/$PRODUCT
fi

subst '1iBuildRequires:rpm-build-python3' $SPEC
subst '1i%add_python3_path /usr/share/atom-beta' $SPEC

# replace embedded git with standalone (due Can't locate Git/LoadCPAN/Error.pm)
EMBDIR=/usr/share/atom-beta/resources/app.asar.unpacked/node_modules/dugite/git
rm -rv $BUILDROOT$EMBDIR/
mkdir -p $BUILDROOT$EMBDIR/bin/
ln -s /usr/bin/git $BUILDROOT$EMBDIR/bin/git
subst "s|.*$EMBDIR/libexec/.*||" $SPEC
subst "s|.*$EMBDIR/share/.*||" $SPEC
subst "s|.*$EMBDIR/ssl/.*||" $SPEC

# replace embedded npm with standalone
EMBDIR=/usr/share/atom-beta/resources/app/apm/node_modules/npm
rm -rv $BUILDROOT$EMBDIR/
ln -s /usr/lib/node_modules/npm $BUILDROOT$EMBDIR
subst "s|.*$EMBDIR/..*\"||" $SPEC

# replace embedded node and npm
for EMBDIR in /usr/share/atom-beta/resources/app/apm/bin/{node,npm} /usr/share/atom-beta/resources/app/apm/node_modules/.bin/{npm,npx} /usr/share/atom-beta/resources/app/apm/node_modules/open/xdg-open ; do
    rm -v $BUILDROOT$EMBDIR
    ln -s /usr/bin/$(basename $EMBDIR) $BUILDROOT$EMBDIR
done

# TODO use separated chromium-sandbox
# TODO for other distros?

# install all requires packages before packing (the list have got with rpmreqs package | xargs echo)
epm install --skip-installed coreutils findutils git-core glib2 grep libalsa libatk libat-spi2-core \
            libcairo libcups libdbus libdrm libexpat libgbm libgdk-pixbuf libgio libgtk+3 libnspr libnss libpango libsecret \
            libX11 libxcb libXcomposite libXdamage libXext libXfixes libxkbcommon libxkbfile libXrandr \
            sed /usr/bin/git /usr/bin/node /usr/bin/npm /usr/bin/npx util-linux which xprop \
            node python3
# enlightenment exo-utils seamonkey

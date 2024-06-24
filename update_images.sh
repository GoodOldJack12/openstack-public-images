#!/bin/bash
source ./common.sh
set -euf -o pipefail
function send_help(){
    cat <<"EOF"
Usage: ./update_images <flags>
Flags:
-f <json_file>  Json file of images to update, default "images.json"
-y              Don't ask for confirmation for each image
-t              Testing mode. Exports TEST=true to ./update_generic.sh so that images are not uploaded.
-h              For when you're confused.
Function:
The script will read a json file and pass the values to update_generic.sh to download, modify and then upload OS images to openstack.
EOF
exit 0
}
OPTSTRING=":ythf:"
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    y)
      YES=true
      ;;
    t)
      export TEST=true
      ;;
    f)
      PARAM=${OPTARG}
      ;;
    h)
      send_help
      ;;
    *)
      warn "Unknown flag"
      send_help
      ;;
  esac
done
IMG_JSON=${PARAM:="images.json"}
# Check for invalid json file
if jq -e "$IMG_JSON" >/dev/null 2>&1; then
    echo "invalid json file!"
    exit 1
fi
# distro, version_name,version_number
function update_image(){
    DISTRO=$1 VERSION_NAME=$2 VERSION_NUMBER=$3 ./update_generic.sh
}
for i in $(seq 0 $(($(jq length $IMG_JSON)-1))); do
    DISTRO="$(jq -r ".[$i].distro" $IMG_JSON)"
    VERSION_NAME="$(jq -r ".[$i].version_name" $IMG_JSON)"
    VERSION_NUMBER="$(jq -r ".[$i].version_number" $IMG_JSON)"

    getConfirmation "Update \"${DISTRO^} $VERSION_NUMBER ($VERSION_NAME)\"?" "Updating \"${DISTRO^} $VERSION_NUMBER ($VERSION_NAME)\""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_image "$DISTRO" "$VERSION_NAME" "$VERSION_NUMBER"
    fi
done

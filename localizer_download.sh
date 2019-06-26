ZIP_FILE_NAME="localizations.zip"
DOMAINS_PATTERN="[,]"
LOCALIZATION_DIRECTORY=${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Localizations

if [ ! -d ${LOCALIZATION_DIRECTORY} ]; then
mkdir -p ${LOCALIZATION_DIRECTORY}
fi

if [ ! -d ${SRCROOT}/${TARGET_NAME} ]; then
mkdir -p ${SRCROOT}/${TARGET_NAME}
fi

for ARGUMENT in "$@"
do
KEY=$(echo $ARGUMENT | cut -f1 -d=)
VALUE=$(echo $ARGUMENT | cut -f2 -d=)
case "$KEY" in
APP_ID)              APP_ID=${VALUE} ;;
SALT)              SALT=${VALUE} ;;
BASE_URL)              BASE_URL=${VALUE} ;;
DOMAINS)    DOMAINS=${VALUE} ;;
*)
esac
done

# GENERATE JSON CONFIG FILE
echo "****** Create Config file ******"
echo "****** App Id: ${APP_ID} ******"
echo "****** Secret: ${SALT} ******"
echo "****** Base Url: ${BASE_URL} ******"
echo "****** Domains: ${DOMAINS} ******"

SPLIT_DOMAINS_PATTERN="\", \""
DOMAINS_SPLITTED=${DOMAINS//${DOMAINS_PATTERN}/${SPLIT_DOMAINS_PATTERN}}

JSON="{\"baseUrl\":\"${BASE_URL}\",\"secret\":\"${SALT}\",\"appId\":\"${APP_ID}\",\"domains\":[\"${DOMAINS_SPLITTED}\"]}"
CONFIG_FILE=configuration.json

cd ${LOCALIZATION_DIRECTORY}
if [ -f ${CONFIG_FILE} ]; then
rm -r ${CONFIG_FILE}
fi

echo ${JSON} >> ${CONFIG_FILE}
# END GENERATE JSON CONFIG FILE

# REQUEST FOR LOCALIZATIONS
echo "****** This is before compilation ******"
echo "Configuration is: ${CONFIGURATION}"  # can be Release or Debug
AUTH_HEADER="X-Authorization: $(printf ${APP_ID}${SALT} | shasum -a 256 | cut -f1 -d" ")"
echo "****** HeaderValue: ${AUTH_HEADER} ******"
LOCALIZATION_URL="${BASE_URL}?app_id=${APP_ID}&domain_id=${DOMAINS//$DOMAINS_PATTERN/&domain_id=}"
echo "****** Localization url: ${LOCALIZATION_URL}  *******"
echo "******  Download the file ${ZIP_FILE_NAME} to ${SRCROOT}/${TARGET_NAME}/ ****** "

# CHECK IF REQUEST IS SUCCESSFUL
if curl -o  ${SRCROOT}/${TARGET_NAME}/${ZIP_FILE_NAME} -H "${AUTH_HEADER}" -v "${LOCALIZATION_URL}" --fail -X GET ; then
    echo "Localizations request is successful."
else
    echo "Localizations request is NOT successful."
    if [ "$CONFIGURATION" = "Release" ]; then
        exit 1 # Meaning of exit codes: https://askubuntu.com/a/892605
    fi
fi

# END REQUEST FOR LOCALIZATIONS

# UNZIP ALL ZIP FILES
echo "****** Unzipping file ${ZIP_FILE_NAME} to ${LOCALIZATION_DIRECTORY} ****** "
unzip -o ${SRCROOT}/${TARGET_NAME}/${ZIP_FILE_NAME} -d ${LOCALIZATION_DIRECTORY}
echo "****** unzipping domain files ***** "

for domain_dir in ${LOCALIZATION_DIRECTORY}/*
do
cd ${domain_dir}
unzip -o "*.zip"
done

echo "****** This is end of before compilation ******"

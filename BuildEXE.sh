#!/bin/bash

echo "BuildMode = ${BuildMode}"

if [ -z "${EXEName}" ]; then
    echo "Missing Environment Variables EXEName"
elif [ -z "${BuildMode}" ]; then
    echo "Missing Environment Variables BuildMode"
elif [ -z "${SiteRootFolder}" ]; then
    echo "Missing Environment Variables SiteRootFolder"
elif [ -z "${HB_COMPILER}" ]; then
    echo "Missing Environment Variables HB_COMPILER"
elif [ "${BuildMode}" != "debug" ] && [ "${BuildMode}" != "release" ] ; then
    echo "You must set Environment Variable BuildMode as \"debug\" or \"release\""
elif [ "${HB_COMPILER}" != "gcc" ]; then
    echo "You must set Environment Variable HB_COMPILER to \"gcc\""
else
    if [ ! -f "${EXEName}_linux.hbp" ]; then
        echo "Invalid Workspace Folder. Missing file ${EXEName}_linux.hbp"
    else
        #The following command most likely will do nothing if the SoftKill task was called first.
        killall "FCGI${EXEName}.exe"

        echo "HB_COMPILER = ${HB_COMPILER}"

        mkdir "build" 2>/dev/null
        mkdir "build/lin64" 2>/dev/null
        mkdir "build/lin64/${HB_COMPILER}" 2>/dev/null
        mkdir "build/lin64/${HB_COMPILER}/${BuildMode}" 2>/dev/null
        mkdir "build/lin64/${HB_COMPILER}/${BuildMode}/hbmk2" 2>/dev/null

        now=$(date +'%m/%d/%Y %H:%M:%S')
        echo local l_cBuildInfo := \"${HB_COMPILER} ${BuildMode} ${now}\">BuildInfo.txt

        rm build/lin64/${HB_COMPILER}/${BuildMode}/${EXEName}.exe 2>/dev/null
        if [ -f "build/lin64/${HB_COMPILER}/${BuildMode}/${EXEName}.exe" ] ; then
            echo "Could not delete previous version of ${EXEName}.exe"
        else

            #  -b        = debug
            #  -w3       = warn for variable declarations
            #  -es2      = process warning as errors
            #  -gc3      = Pure C code with no HVM
            #  -p        = Leave generated ppo files

            if [ "${BuildMode}" = "debug" ] ; then
                hbmk2 "${EXEName}_linux.hbp" "vscode_debugger.prg" "${HB_FASTCGI_ROOT}/hb_fcgi/hb_fcgi_linux.hbm" -b  -p -w3 -shared
            else
                hbmk2 "${EXEName}_linux.hbp" "${HB_FASTCGI_ROOT}/hb_fcgi/hb_fcgi_linux.hbm" -w3 -static
                # -static
                # -fullstatic
            fi
            nHbmk2Status=$?
            if [ ! -f  "build/lin64/${HB_COMPILER}/${BuildMode}/${EXEName}.exe" ]; then
                echo "Failed To build ${EXEName}.exe"
            else
                if [ $nHbmk2Status -eq 0 ]; then
                    echo ""
                    echo "No Errors"

                    rm "${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe"

                    if [ -f "${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe" ] ; then
                        echo "Failed to delete previous version of ${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe"
                    else
                        cp "build/lin64/${HB_COMPILER}/${BuildMode}/${EXEName}.exe" "${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe"

                        if [ -f "${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe" ] ; then
                            echo "Copied file build/lin64/${HB_COMPILER}/${BuildMode}/${EXEName}.exe to ${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe"
                        else
                            echo "Failed to update file ${WebsiteDrive}${SiteRootFolder}backend/FCGI${EXEName}.exe"
                        fi

                        #cp "../../fcgi-2.4.1/libfcgi/${HB_COMPILER}/release/libfcgi.dll" "${WebsiteDrive}${SiteRootFolder}backend/libfcgi.dll"

                        echo Current time is ${now}
                        echo ""
                        echo "Ready            BuildMode = ${BuildMode}"
                    fi
                    
                else
                    echo Current time is ${now}
                    echo "Compilation Error"

                    if [ $nHbmk2Status -eq  1 ]; then echo "Unknown platform" ; fi
                    if [ $nHbmk2Status -eq  2 ]; then echo "Unknown compiler" ; fi
                    if [ $nHbmk2Status -eq  3 ]; then echo "Failed Harbour detection" ; fi
                    if [ $nHbmk2Status -eq  5 ]; then echo "Failed stub creation" ; fi
                    if [ $nHbmk2Status -eq  6 ]; then echo "Failed in compilation (Harbour, C compiler, Resource compiler)" ; fi
                    if [ $nHbmk2Status -eq  7 ]; then echo "Failed in final assembly (linker or library manager)" ; fi
                    if [ $nHbmk2Status -eq  8 ]; then echo "Unsupported" ; fi
                    if [ $nHbmk2Status -eq  9 ]; then echo "Failed to create working directory" ; fi
                    if [ $nHbmk2Status -eq 10 ]; then echo "Dependency missing or disabled" ; fi
                    if [ $nHbmk2Status -eq 19 ]; then echo "Help" ; fi
                    if [ $nHbmk2Status -eq 20 ]; then echo "Plugin initialization" ; fi
                    if [ $nHbmk2Status -eq 30 ]; then echo "Too deep nesting" ; fi
                    if [ $nHbmk2Status -eq 50 ]; then echo "Stop requested" ; fi

                fi
            fi
        fi
    fi
fi

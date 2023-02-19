define(['util/calibration', 'util/spg', 'util/iso3166'], (calibrationUtil, spgUtil, iso3166) => {
    return ($scope, $websocket, $document, $mdDialog, $mdToast, $http, $interval) => {
        // Debug myScope
        myScope = $scope;
        myWebSocket = $websocket;
        $scope.recentlyInteracted = false; // block MSO Delta Servicer up to 3 seconds after user interactions
        $scope.recentlyInteractedTimeout = null;
        $scope.mso = {};
        $scope.reload = false; // to reload home page after update reboot
        $scope.servermso = {};
        $scope.spgUtil = spgUtil;
        $scope.countrycodes = iso3166.isoCountries;
        $scope.wifiNetworks = [];
        $scope.nmstat = {};
        $scope.network = {
            eth0:{
                uuid: null
            },
            wlan0:{
                uuid: null
            }
        };
        $scope.debugmsg = '';

        extractVerb = cmd => {
            let i = cmd.indexOf(" ");
            return (i > 0) ? cmd.slice(0, i) : cmd;
        }

        extractArg = cmd => {
            let i = cmd.indexOf(" ");
            return (i > 0) ? JSON.parse(cmd.slice(i + 1)) : undefined;
        }

        $scope.showingDisconnectDialog = false;
        $scope.initConnectFail = setTimeout($scope.showDisconnectDialog, 5000);

        // WebSocket handler
        $scope.socket = $websocket(`ws://${window.location.protocol == "file:" ? "localhost" : window.location.host}/ws/controller`, { "reconnectIfNotNormalClose": true, "maxTimeout": 10000 })
            .onMessage(event => {
                // This code processes the incoming verbs sent from the server and looks them up in the local verb routing table. ($scope.verbs)
                let verb = extractVerb(event.data);
                let arg = extractArg(event.data);
                // Look up in the verb routing table and run the respective function
                if ($scope.verbs[verb]) $scope.verbs[verb](arg)
                else console.log("Could not process verb '" + verb + "'"); // If the verb handler is not found.
            })
            .onOpen(() => {
                if ($scope.reload) {
                    // reload home page after update reboot
                    console.log('Reload home page because reload is true');
                    $scope.reload = false;
                    window.location.href = "/";
                }

                clearTimeout($scope.initConnectFail);
                if ($scope.showingDisconnectDialog) $scope.closeDialog();
                $scope.socket.send("getmso");
                $scope.$apply();
            })
            .onClose(() => {
                if (($scope.mso !== undefined) &&
                    ($scope.mso.stat !== undefined) &&
                    ($scope.mso.stat.updateprogmsg !== undefined) &&
                    ($scope.mso.stat.updateprogmsg.reboot !== undefined) &&
                    ($scope.mso.stat.updateprogmsg.reboot)) {
                    $scope.reload = true;
                    $scope.mso.stat.updateprogmsg.reboot = false;
                }
                console.log("onClose called - Calling showDisconnectDialog()");
                $scope.showDisconnectDialog();
                $scope.$apply();
            });
        var mainSocket = $scope.socket;

        function applyProductRules() {
            var groups = ['c', 'lrs', 'lrb', 'lrw', 'lrtf', 'lrtm', 'lrtr', 'lrhf', 'lrhr', 'sub1', 'sub2', 'sub3', 'sub4', 'sub5'];
            var spg = $scope.mso.speakers.groups;
            groups.forEach(group => {
                if (spg[group] == undefined) spg[group] = { present: false, size: 'l', fc: 40 };
            });
            if (spg.lrb.present && !spg.lrs.present) {
                displayWarning (" Cannot have rear surround (back) speakers if there are no surrounds");
            }         
            spg.lrb.present = spg.lrb.present && spg.lrs.present; // No backs when no surround

            if (spg.lrw.present && !spg.lrb.present) {
                displayWarning (" Cannot have wide speakers if there are no rear surrounds (backs}");
            }         
            spg.lrw.present = spg.lrw.present && spg.lrb.present; // No wides when no backs  

            if (spg.lrhf.present && spg.lrtf.present) {
                displayWarning (" Cannot have height front speakers if there are top fronts present");
            }      
            spg.lrhf.present = spg.lrhf.present && (!spg.lrtf.present); // No height front if top front present

            if ((!spg.lrs.present) && (spg.lrtm.present) && (spg.lrtf.present || spg.lrtr.present || spg.lrhf.present || spg.lrhr.present)) {
                displayWarning ("If there are no surrounds and top middle is selected, heights or top front speakers are not allowed - same for rear heights and rear tops");
                spg.lrtf.present = false;
                spg.lrtr.present = false;
                spg.lrhf.present = false;
                spg.lrhr.present = false;
            };
            if ((!spg.lrs.present) && (!spg.lrtm.present) && (spg.lrtr.present || spg.lrhr.present)) {
                displayWarning ("If there are no surrounds and top middle is NOT selected, then either front heights or front tops are allowed but no rear heights or rear tops");
                spg.lrtf.present = spg.lrtf.present && (!spg.lrhf.present)
                spg.lrtr.present = false;
                spg.lrhr.present = false;
            };
            if ((!spg.c.present) && (!spg.lrb.present)) {
                spg.lrtm.present = false;
            };
            spg.lrtf.present = spg.lrtf.present && (!spg.lrhf.present); // only one front allowed
            spg.lrtr.present = spg.lrtr.present && (!spg.lrhr.present); // only one rear allowed
            if ((!spg.lrtf.present) && (!spg.lrhf.present)) {
                spg.lrhr.present = false; // no fronts . clear rears
                spg.lrtr.present = false;
            };
            // No top middle when top front present but top rear not present
            if (spg.lrtm.present && spg.lrtf.present) {
                if ((!spg.lrtr.present) && (!spg.lrhr.present)) {
                    spg.lrtm.present = false;
                }
            }
            if (spg.lrtm.present && spg.lrhf.present) {
                if ((!spg.lrtr.present) && (!spg.lrhr.present)) {
                    spg.lrtm.present = false;
                }
            }


            spg.sub2.present = spg.sub2.present && spg.sub1.present; // No sub2 without sub
            spg.sub3.present = spg.sub3.present && spg.sub2.present; // No sub3 without sub2
            spg.sub4.present = spg.sub4.present && spg.sub3.present; // No sub4 without sub3
            spg.sub5.present = spg.sub5.present && spg.sub4.present; // No sub5 without sub4

            Object.keys(spg).forEach(groupName => {
                group = spg[groupName];
                if (group.fc) {
                    group.fc = Math.round(group.fc / 10) * 10;
                };
            });
            if ($scope.mso.fastStart == "off") {
                $scope.mso.fastStartPassThrough = "off";
            };
            return;
        }

 function spgFromGroups(){
     if ($scope.mso.speakers===undefined) {
         return;
     }
     var groups = ['c', 'lrs', 'lrb', 'lrw', 'lrtf', 'lrtm', 'lrtr', 'lrhf', 'lrhr', 'sub1', 'sub2', 'sub3', 'sub4', 'sub5'];
     var spg = $scope.mso.speakers.groups;
    // Count number of speakers selected - count must be <= 16 for valid setup
    // Compile list of active speaker groups.
    let mains = 2; // The 'lr' group is always present.
    let subs = 0;
    let frontTops = 0;
    let frontHeights =0;
    let middleTop = 0;
    let rearTops = 0;
    let rearHeights =0;
    let uppers = 0;
    groups.forEach(group => {
        if (spg[group] == undefined) spg[group] = { present: false, size: 'l', fc: 40 };
    })
    Object.keys(spg).forEach(x=>
    {
       switch(x)
       {
           case 'lr':
               break;
           case 'c':
               mains+=spg[x].present?1:0;
               break;
           case 'lrs':
           case 'lrb':
           case 'lrw':
               mains+=spg[x].present?2:0;
               break;
           case 'lrtf':
               frontTops+=spg[x].present?2:0;
               break;
           case 'lrtm':
               middleTop+=spg[x].present?2:0;
               break;
           case 'lrtr':
               rearTops+=spg[x].present?2:0;
               break;
           case 'lrhf':
               frontHeights+=spg[x].present?2:0;
               break;
           case 'lrhr':
               rearHeights+=spg[x].present?2:0;
               break;
           case 'sub1':
           case 'sub2':
           case 'sub3':
           case 'sub4':
           case 'sub5':
               subs+=spg[x].present?1:0;
               break;
       }
    });
        uppers = frontTops + middleTop + rearTops + frontHeights + rearHeights;
     var total = mains + subs + uppers;
     if ((total < 17)) {
         return true;
     }
     else  {
         displayWarning (" a maximum of 16 speakers is allowed \n the last speaker group added is ignored")
         return false;
     }
     //console.log("Number of speakers'"  total);
 } // end definition of function spgFromGroups


        // MSO Watcher
        $scope.$watch('mso', (newValue, oldValue) => {
            // console.log('watcher', newValue, oldValue)
            // This code is executed whenever the local value of mso changes. This is what drives MSO change requests.
            if (spgFromGroups()){
            }
            else {
                angular.copy(oldValue,newValue);
                return;
            }
            if (!$scope.msoReceived) return;
            // Pre-apply Product Rules. To prevent recursive changemso commands, exit if the applyProductRules() returns true, because another watch-trigger will follow.
            // if(applyProductRules()) return;
            try {
                applyProductRules();
            } catch (exc) {}
            // Do not run changemso if the mso agrees with that last sent by the server.
            if (angular.equals($scope.servermso, newValue) && !$scope.recentlyInteracted) {
                console.log('Do not run changemso if the mso agrees with that last sent by the server.')
                return;
            };
            // Log that user recently interacted with UI
            $scope.recentlyInteracted = true;
            clearTimeout($scope.recentlyInteractedTimeout);
            $scope.recentlyInteractedTimeout = setTimeout(function() {
                // console.log('timeout reached');
                $scope.recentlyInteracted = false;
                // no longer recently interacted - apply received patch queue
                $scope.updateLocalMSO();
            }, 2500);
            // Generate Patch
            let patch = jsonpatch.compare(oldValue, newValue);
            $scope.socket.send("changemso " + JSON.stringify(patch));
            // Send the patch to the server.
            console.debug("Sending changemso " + JSON.stringify(patch));
            if ((patch[0].path == '/powerIsOn') && (!patch[0].value)) {
                // dismiss dialogbox when going to sleep
                $scope.closeDialog();
            }
        }, true);

        $scope.onCalToolConnected = (connected) => {
            if ($scope.diracLockedOut) {
                if (!connected) $scope.closeDialog();
            } else {
		// show dirac lockout popup only on Home page and not on status (LCD)
                if ((connected) && (location.pathname !== '/status.html')) {
			$scope.showDiracLockout();
		}
            }
        }

        $scope.$watch('mso.cal.caltoolconnected', $scope.onCalToolConnected);

        $scope.updateLocalMSO = () => {
            let localPatch = jsonpatch.compare($scope.servermso, $scope.mso);
            console.log('updateLocalMSO', localPatch);
            // no need to update mso if servermso already agrees with mso
            // avoids triggering mso watcher needlessly
            if (localPatch.length > 0) {
                angular.copy($scope.servermso, $scope.mso);
            }
        }

        // Server MSO Delta Servicer
        $scope.updateMSO = patch => {
            
            // apply patch to servermso immediately
            $scope.servermso = jsonpatch.applyPatch($scope.servermso, patch).newDocument;

            // if the user interacted recently, keep the interaction flag
            // until we stop receiving messages in order to avoid
            // applying prematurely 
            if ($scope.recentlyInteracted) {
                clearTimeout($scope.recentlyInteractedTimeout);
                $scope.recentlyInteractedTimeout = setTimeout(function() {
                    // console.log('timeout reached');
                    $scope.recentlyInteracted = false;
                    // no longer recently interacted - apply to local MSO
                    $scope.updateLocalMSO();
                }, 1000);
            } else {
                // apply immediately
                $scope.updateLocalMSO();
            }
        }

        $scope.msoReceived = false;

        // Server MSO replacement servicer
        $scope.receiveMSO = newmso => {
            angular.copy(newmso, $scope.servermso);
            angular.copy(newmso, $scope.mso);
            $scope.msoReceived = true;
        }

        $scope.showError = errormsg => {
            console.error("Server Error: ", errormsg);
            // Revert changes to what the server last had.
            angular.copy($scope.servermso, $scope.mso);
        }

        $scope.confirmFactoryReset = () => {
            $mdDialog.show($mdDialog.confirm()
                           .title("Confirm Factory Reset")
                           .textContent("All settings will be restored to factory default. Network settings and Dirac calibrations are not changed.")
                           .ok("Confirm")
                           .cancel("Abort")
                           .multiple(true))
                .then(()=>{
             $scope.socket.send('factoryreset');
            })
        }
        $scope.updateAPM253 = () => {
            $mdDialog.show($mdDialog.confirm()
                           .title("Confirm Firmware Update")
                           .textContent("Internal DSP firmare will be updated to v253")
                           .ok("Confirm")
                           .cancel("Abort")
                           .multiple(true))
                .then(()=>{
             $scope.socket.send('updatefirmware253');
             window.location.href = "/";
            })
        }


        $scope.showingBTDialog = false;

        $scope.btEvent = ev => {
            if (ev && ev.type) {
                switch (ev.type) {
                    case "requestconfirmation":
                        $mdDialog.show({
                            targetEvent: event,
                            // This template must be embedded; it isn't going to be available as a separate file when the connection is lost.
                            template: '<md-dialog aria-label="Bluetooth Pairing Request">' +
                                '<md-toolbar>' +
                                '    <div class="md-toolbar-tools">' +
                                '        <md-icon>bluetooth</md-icon>' +
                                '        <h2 flex>Bluetooth Pairing Request</h2>' +
                                '    </div>' +
                                '</md-toolbar>' +
                                '<md-dialog-content class="md-padding">' +
                                '    <p>Pairing request from device ' + ev.name + '.</p>' +
                                '    <p>Confirm the following PIN code matches that on device:</p>' +
                                '    <p style="font-size: 200%">' + ev.passkey + '</p>' +
                                '</md-dialog-content>' +
                                '<md-dialog-actions layout="row">' +
                                '   <md-button md-autofocus ng-click="acceptPair()">Pair</md-button>' +
                                '   <md-button ng-click="rejectPair()">Reject</md-button>' +
                                '</md-dialog-actions>' +
                                '</md-dialog>',
                            preserveScope: true,
                            clickOutsideToClose: true,
                            escapeToClose: false,
                            controller: ($scope, $mdDialog) => {
                                $scope.mso = myScope.mso;
                                $scope.cancel = function() {
                                    $mdDialog.hide();
                                };
                                $scope.acceptPair = () => {
                                    mainSocket.send('btreply {"reply":"accept"}');
                                    console.log("Accept Pair");
                                    $mdDialog.hide();
                                }
                                $scope.rejectPair = () => {
                                    mainSocket.send('btreply {"error":"reject"}');
                                    console.log("Reject Pair");
                                    $mdDialog.hide();
                                }
                            },
                            multiple: true,
                            onShowing: () => {},
                            onComplete: () => { $scope.showingBTDialog = true; },
                        }).then(() => {});
                        break;
                    case "cancel":
                        if ($scope.showingBTDialog) $mdDialog.hide();
                        break;
                    default:
                        break;
                }
            }
        }

        $scope.scan = () => {
            $scope.socket.send(`netapply {"action":"nmstat"}`);
        }

        $scope.wificonfig = (ssid, password) => {
            if (password)
                $scope.socket.send(`netapply {"action":"add", "ssid":${JSON.stringify(ssid)}, "password":${JSON.stringify(password)} }`);
        }

        $scope.wificonnect = conid => {
            $scope.socket.send(`netapply {"action":"connect", "conid":"${conid}" }`);
        }

        $scope.wifidisconnect = conid => {
            $scope.socket.send(`netapply {"action":"disconnect", "conid":"${conid}" }`);
        }

        $scope.wififorget = conid => {
            $scope.socket.send(`netapply {"action":"delete", "conid":"${conid}" }`);
        }

        $scope.getConDetails = conid => {
            $scope.socket.send(`netapply {"action":"getcondetail", "conid":"${conid}" }`);
        }

        $scope.wifipower = enable => {
            $scope.socket.send(`netapply {"action":"radio", "enable":${enable} }`);
        }

        $scope.reseteth0 = () => {
            $scope.socket.send(`netapply {"action":"reset" }`);
        }

        $scope.onWifiNetworks = nets => {
            var selected = $scope.selnet;
            if (selected) {
                var selidx = nets.findIndex(net => ((net.ssid == selected.ssid) && (net.channel == selected.channel)));
                if (selidx == -1)
                    nets.unshift(selected); // Push to front
                else
                    nets[selidx] = selected; // Replace with reference.
            } else
                $scope.selnet = nets[0]; // Select first network on list by default. (Avoids empty item at top of list)
            $scope.wifiNetworks = nets;
            $scope.$apply;
        }

        $scope.onConfiguredNetworks = nets => {
            var selected = $scope.actnet;
            if (selected) {
                var selidx = nets.findIndex(net => (net.UUID == selected.UUID));
                if (selidx == -1)
                    $scope.actnet = nets[0]; // Connection doesn't exist anymore.
                else
                    nets[selidx] = selected; // Replace with reference.
            } else
                $scope.actnet = nets[0]; // Select first network on list by default. (Avoids empty item at top of list)
            $scope.configuredNetworks = nets;
            $scope.$apply;
        }

        $scope.nmstatpopulated = false;

        $scope.populateNetworkFromConfig = (interface, config) => {
            var net = $scope.network[interface];
            net.dhcp = config.ipv4.method=='auto';
            if(net.dhcp)
            {
                // Fill in blank config so we have it if user goes to manual.
                net.addresses = [{
                    address: '',
                    prefixlen: 24,
                    netmask: '255.255.255.0'
                }];
                net.gateway="";
                net.dns=[""];
            }
            else {
                net.addresses = config.ipv4.addresses.split(',').map(addr => {
                    addr = addr.trim();
                    return {
                        address: addr.split('/')[0],
                        prefixlen: addr.split('/')[1],
                        netmask: cidr2mask(addr.split('/')[1]),
                    }
                });
                net.gateway = config.ipv4.gateway;
                net.dns = config.ipv4.dns.split(',');
            }
            net.uuid = config.GENERAL.UUID;
        }

        $scope.onNetworkManagerStat = nmstat => {
            $scope.network.radioenabled = nmstat.radioenabled;
            $scope.onWifiNetworks(nmstat.wifinets);
            $scope.onConfiguredNetworks(nmstat.cons.filter(con => con.TYPE == "802-11-wireless"));
            // Filter it here...
            if(!$scope.nmstatpopulated)
            {
                $scope.nmstatpopulated = true;
                $scope.populateNetworkFromConfig("eth0", nmstat.eth0detail);
                if($scope.actnet && $scope.actnet.UUID) $scope.getConDetails($scope.actnet.UUID); // Populate the data for this network.
            }
            $scope.nmstat = nmstat;
            $scope.$apply();
        }

        $scope.onConnectionDetail = netdetail => {
            // First check the network detail
            // if(netdetail.uuid==$scope.network["eth0"].uuid) {} // For later routing
            if(!netdetail.connection)
            // if(netdetail.connection.type!="802-11-wireless") return; // Not 802.11 wireless. This isn't right.
            $scope.populateNetworkFromConfig("wlan0", netdetail);
            $scope.net = netdetail;
            $scope.$apply();
        }

        $scope.applyNetworkConfig = netconfig => {
            $scope.socket.send(`netapply {"action":"conedit", "config":${JSON.stringify(netconfig)} }`);
        }

        $scope.mask2cidr = mask2cidr;

        var netUpdateStop;

        $scope.$watch('selectab', (newTab, oldTab, tabScope) => {
            if (newTab == 6) {
                if (angular.isDefined(netUpdateStop)) return;
                netUpdateStop = $interval($scope.scan, 5000);
            } else if (oldTab == 6) {
                if (angular.isDefined(netUpdateStop)) {
                    $interval.cancel(netUpdateStop);
                    netUpdateStop = undefined;
                }
            }

        });

        // cancel any dialogs if power is turned off
        $scope.$watch('mso.powerIsOn', pwrstat => {
            if(!pwrstat) $mdDialog.cancel();
        });

        // This is the verb routing table. These are the verbs that the server may send to the client, and their respective callbacks.
        $scope.verbs = {
            "mso": $scope.receiveMSO,
            "msoupdate": $scope.updateMSO,
            "error": $scope.showError,
            "btevent": $scope.btEvent,
            "wifinetworks": $scope.onWifiNetworks,
            "nmcondetail": $scope.onConnectionDetail,
            "nmcons": $scope.onConfiguredNetworks,
            "nmstat": $scope.onNetworkManagerStat,
            "forcereload": () =>document.location.reload(),
            "updateprog": $scope.updateprog
        }

        $scope.attachDiagram = contentId => {
            // Get a jQuery object containing all the speaker icons (class spk)
            let diagram = $(contentId + ' .spk');
            // Attach a click handler to each of them
            diagram.click(ev => {
                // Content of click handler.
                let speaker = ev.target.id;
                $mdDialog
                    .show({
                        templateUrl: 'templates/speaker-dialog.html',
                        locals: {
                            'spk': speaker,
                            'mso': $scope.mso
                        },
                        bindToController: true,
                        clickOutsideToClose: true,
                        controller: ($scope, $mdDialog, spk, mso) => {
                            $scope.spk = spk;
                            $scope.mso = mso;
                            $scope.closeDialog = () => $mdDialog.hide();
                        }
                    })
                    .finally(function() {});
            });
        }

        $scope.toggleMute = () => {
            $scope.socket.send('avcui "m"');
        }

/*
        $scope.showPowerDownOption = () => {
            console.log("in showPowerDownOption()");
            $mdDialog.show($mdDialog.confirm()
                           .title("Power Down")
                           .textContent("Are you sure you want to turn power off?")
                           .ok("Confirm")
                           .cancel("Cancel")
                           .multiple(true))
                .then(()=>{
                $scope.mso.powerIsOn=false;   // power down
            }, ()=>            {
                console.log("User dismissed confirm dialog");
            });
        }
*/
        $scope.showPowerDownOption = (event) => {
            console.log("in showPowerDownOption()");
            $scope.mso = myScope.mso;
            $scope.mso.powerAction="none";
            $mdDialog.show({
                targetEvent: event,
                template: 
                    `<md-dialog aria-label="Power Down Options">
                      <form ng-cloak>
                        <md-dialog-content>
                          <div class="md-dialog-content">
                            <ul>
                            <li>Shutdown: Orderly shutdown the system and enter low power state</li>
                            <li>Sleep: Turn off Front Panel and sleep awaiting fast wake up</li>
                            <li>Restart: Orderly shutdown and then restart the system</li>
                            <li>Cancel: Do nothing</li>
                            </ul>
                          </div>
                        </md-dialog-content>

                        <md-dialog-actions layout="row">
                          <span flex>
                              <md-button ng-click="answerfn('shutdown')">
                                Shutdown
                              </md-button>
                              <md-button ng-click="answerfn('sleep')">
                                Sleep
                              </md-button>
                              <md-button ng-click="answerfn('restart')">
                                Restart
                              </md-button>
                              <md-button ng-click="answerfn('cancel')">
                                Cancel
                              </md-button>
                          </span>
                        </md-dialog-actions>
                      </form>
                    </md-dialog>`,
                preserveScope: true,
                clickOutsideToClose: true,
                escapeToClose: false,
                controller: ($scope, $mdDialog) => {
                    $scope.mso = myScope.mso;
                    $scope.cancel = function() {
                        $mdDialog.hide();
                    };
                    $scope.answerfn = (answer) => {
                        console.log("answer is "+answer);
                        if ((answer === "sleep")) {
                            // Command flows through node red to put system to sleep
                            $scope.mso.powerAction="sleep";
                            console.log("sleep");
                        }
                        if ((answer === "shutdown")) {
                            console.log("off");
                            $scope.mso.powerAction="off";
                            // Command flows through node red to power off Linux
                        }
                        if ((answer === "restart")) {
                            console.log("restart");
                            $scope.mso.powerAction="reboot";
                        }
                        $mdDialog.hide();
                    }
                },
                multiple: true,
                onShowing: () => {},
             //   onComplete: () => { $scope.showingBTDialog = true; },
            }).then(() => {});
        }


        $scope.showSettings = (event) => {
            $mdDialog.show({
                targetEvent: event,
                templateUrl: 'templates/config-dialog.html',
                preserveScope: true,
                clickOutsideToClose: true,
                controller: DialogController,
                onShowing: () => {
                    if ($scope.selectab == 6) {
                        if (angular.isDefined(netUpdateStop)) return;
                        netUpdateStop = $interval($scope.scan, 3000);
                    }
                },
                onRemoving: () => {
                    if (angular.isDefined(netUpdateStop)) {
                        $interval.cancel(netUpdateStop);
                        netUpdateStop = undefined;
                    }
                }
            });
        }

        $scope.showDetails = (event) => {
            $mdDialog.show({
                targetEvent: event,
                templateUrl: 'templates/detailed-status.html',
                preserveScope: true,
                clickOutsideToClose: true,
                controller: DialogController
            });
        }

        $scope.showHelp = (event) => {
            $mdDialog.show({
                targetEvent: event,
                templateUrl: 'help.html',
                preserveScope: true,
                clickOutsideToClose: true,
                controller: DialogController
            });
        }

        $scope.showSettingsHelp = (event, tabId) => {
            window.open('help-tab' + tabId + '.html');
            console.log("in showSettingsHelp");
        }


        $scope.fpSettings = (event) => {
            $mdDialog.show({
                targetEvent: event,
                templateUrl: 'templates/frontpanel-dialog.html',
                preserveScope: true,
                clickOutsideToClose: true,
                controller: DialogController
            });
        }

        $scope.showInputsDialog = (event) => {
            $mdDialog.show({
                targetEvent: event,
                templateUrl: 'templates/inputs-dialog.html',
                preserveScope: true,
                clickOutsideToClose: true,
                controller: DialogController
            });
        }

        $scope.nextDtsDiaglogEnh = (dialogEnh) => {
            dialogEnh++;
            if (dialogEnh > 6) {
                dialogEnh = 0;
            }
            return (dialogEnh);
        }


        $scope.diracLockedOut = false;

        $scope.showDiracLockout = (event) => {
            $scope.diracLockedOut = true;
            $mdDialog.show({
                targetEvent: event,
                templateUrl: 'templates/dirac-lockout.html',
                preserveScope: true,
                clickOutsideToClose: false,
                escapeToClose: false,
                controller: DialogController,
                multiple: true,
                onShowing: () => { $scope.diracLockedOut = true },
                onComplete: () => { $scope.onCalToolConnected($scope.mso.cal.caltoolconnected) }
            }).then(() => {
                $scope.diracLockedOut = false;
                $scope.onCalToolConnected($scope.mso.cal.caltoolconnected);
            });
        }

        $scope.showDisconnectDialog = (event) => {
            $mdDialog.hide(); // Hide any existing dialogs
            $mdDialog.show({
                targetEvent: event,
                // This template must be embedded; it isn't going to be available as a separate file when the connection is lost.
                template: `
                <md-dialog aria-label="System Offline">
                <md-toolbar>
                    <div class="md-toolbar-tools">
                        <md-icon>cloud_off</md-icon>
                        <h2 flex>System Offline</h2>
                    </div>
                </md-toolbar>
                <md-dialog-content class="md-padding">
                    <p>The system is offline.</p>
                    <p>The configuration page will be available after the system returns to online state.</p>
                    <p>There is no need to reload the page.</p>
                </md-dialog-content>
            </md-dialog>`,
                preserveScope: true,
                clickOutsideToClose: false,
                escapeToClose: false,
                controller: DialogController,
                multiple: true,
                onShowing: () => { $scope.showingDisconnectDialog = true },
                onComplete: () => { /* $scope.onCalToolConnected($scope.mso.cal.caltoolconnected) */ }
            }).then(() => {
                $scope.diracLockedOut = false;
                $scope.onCalToolConnected($scope.mso.cal.caltoolconnected);
            });
        }



        $scope.closeDialog = () => {
            $mdDialog.hide();
        }

        $scope.populateCal = calibrationUtil.populateCal($scope);

        //       if ($scope.mso.speakers.uppermode != 'height') spg.lrhf.present = spg.lrhr.present = false; // Heights cannot be active when not in uppermode height
        //       if ($scope.mso.speakers.uppermode != 'top') spg.lrtf.present = spg.lrtm.present = spg.lrtr.present = false; // Tops cannot be active when not in uppermode top

        $scope.activeChannels = (spg) => {
            //            return spgUtil.spgToSp(Object.keys(spgUtil.bmg).filter(spgName => {
            //                if(spgName=='lr') return true;
            //                return (spg[spgName] && spg[spgName].present);
            //            }));
            var allKeys = Object.keys(spgUtil.bmg);
            var filterFn = (spgName) => {
                if (spgName == 'lr') return true;
                var present;


                present = spg[spgName] && spg[spgName].present;
                return (present);
            };
            var filtered = allKeys.filter(filterFn);
            var translated = spgUtil.spgToSp(filtered);
            return (translated);

        }

        $scope.nextDtsDiaglogLvl = (dialogEnh) => {
            dialogEnh++;
            if (dialogEnh > 6) {
                dialogEnh = 0;
            }
            return (dialogEnh);
        }

        // The order is:  on->bypass->off->on
        // Just change the MSO state.  The flow sends avcUi commands.
        $scope.diracToggle = ()=> {
            switch ($scope.mso.cal.diracactive) {
            case 'on':
                $scope.mso.cal.diracactive = 'bypass';
                break;
            case 'off':
                $scope.mso.cal.diracactive = 'on';
                break;
            default:
            case 'bypass':
                $scope.mso.cal.diracactive = 'off';
                break;
            }
        }

        $scope.applyNetwork = nif => $scope.socket.send('netapply "' + nif + '"');


        DialogController = ($scope, $mdDialog) => {
            $scope.mso = myScope.mso;
            $scope.cancel = function() {
                $mdDialog.hide();
            };
            $scope.showSettingsHelp = myScope.showSettingsHelp;
        }
    }
});

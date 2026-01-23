// Index.ets
import { A2ARestaurantOfficialHandler } from './A2Ainterceptor';
import {A2UIInArkWeb} from './A2UIInArkweb'
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, Permissions, common } from '@kit.AbilityKit';
import { BusinessError, emitter } from '@kit.BasicServicesKit';

const permissions: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];

/**
 * 申请权限异步函数
 * @returns true: 全部权限已授权; false: 存在拒绝的权限或出错
 */
async function reqPermissionsFromUser(permissions: Array<Permissions>,
  context: common.UIAbilityContext): Promise<boolean> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

  try {
    // 使用 await 等待权限请求结果
    let data = await atManager.requestPermissionsFromUser(context, permissions);

    let grantStatus: number[] = data.authResults;
    let length: number = grantStatus.length;

    for (let i = 0; i < length; i++) {
      if (grantStatus[i] !== 0) {
        // 只要有一个权限被拒绝，就返回 false
        console.warn(`${permissions[i]} was denied by user.`);
        return false;
      }
      console.info(`${permissions[i]} is granted by user.`);
    }

    // 所有权限均已授权
    return true;

  } catch (err) {
    let error = err as BusinessError;
    console.error(`Failed to request permissions from user, code: ${error.code}, message: ${error.message}`);
    return false;
  }
}
@Entry
@Component
struct Index {
  aboutToAppear(): void {
    this.getCurrentLocation();
  }
  // 获取当前位置
  private async getCurrentLocation() {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await reqPermissionsFromUser(permissions, context);
    let request: geoLocationManager.SingleLocationRequest = {
      'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
      'locatingTimeoutMs': 10000
    }
    try {
      geoLocationManager.getCurrentLocation(request).then((result) => { // 调用getCurrentLocation获取当前设备位置，通过promise接收上报的位置
        console.log('current location: ' + JSON.stringify(result));
        let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest =
          { "latitude": result.latitude, "longitude": result.longitude, "maxItems": 1 };
        try {
          geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest, (err, data) => {
            if (err) {
              console.log('getAddressesFromLocation err: ' + JSON.stringify(err));
            } else {
              console.log('getAddressesFromLocation data: ' + JSON.stringify(data));
              AppStorage.setOrCreate('currentUserAddress',
                `${data[0].countryName}${data[0].administrativeArea}${data[0].subAdministrativeArea ===
                data[0].administrativeArea ? '' :
                  data[0].subAdministrativeArea}${data[0].locality === data[0].subAdministrativeArea ? '' :
                  data[0].locality}${data[0].subLocality}${data[0].roadName}`)
              emitter.emit('LocationUpdated');
            }
          });
        } catch (err) {
          console.error("errCode:" + JSON.stringify(err));
        }
      })
        .catch((error: BusinessError) => { // 接收上报的错误码
          console.error('promise, getCurrentLocation: error=' + JSON.stringify(error));
        });
    } catch (err) {
      console.error("errCode:" + JSON.stringify(err));
    }
  }
  build() {
    Column() {
      A2UIInArkWeb()
        .width('100%')
        .height('100%')
    }
  }

}
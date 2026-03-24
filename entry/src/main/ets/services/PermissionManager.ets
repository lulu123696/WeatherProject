import { abilityAccessCtrl, bundleManager, common, Permissions, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export async function checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  // 获取应用程序的accessTokenID。
  let tokenId: number = 0;
  try {
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get bundle info for self, code: ${err.code}, message: ${err.message}`);
  }

  // 校验应用是否被授予权限。
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to check access token, code: ${err.code}, message: ${err.message}`);
  }

  return grantStatus;
}

/**
 * 申请用户授权。authResults 全为 0 表示全部授予。
 */
export async function requestPermissionsFromUserAsync(
  permissions: Array<Permissions>,
  context: common.UIAbilityContext
): Promise<boolean> {
  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  try {
    const data = await atManager.requestPermissionsFromUser(context, permissions);
    const grantStatus: number[] = data.authResults;
    for (let i = 0; i < grantStatus.length; i++) {
      if (grantStatus[i] !== 0) {
        return false;
      }
    }
    return true;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to request permissions from user, code: ${err.code}, message: ${err.message}`);
    return false;
  }
}

/**
 * 跳转系统设置中本应用详情页，便于用户手动打开权限。
 */
export async function openApplicationPermissionSettings(context: common.UIAbilityContext): Promise<void> {
  let bundleName = '';
  try {
    const bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    bundleName = bundleInfo.name;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`getBundleInfoForSelf failed, code: ${err.code}, message: ${err.message}`);
    return;
  }
  const parameters: Record<string, Object> = {};
  parameters['pushParams'] = bundleName;
  const want: Want = {
    bundleName: 'com.huawei.hmos.settings',
    abilityName: 'com.huawei.hmos.settings.MainAbility',
    uri: 'application_info_entry',
    parameters
  };
  try {
    await context.startAbility(want);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to open app settings, code: ${err.code}, message: ${err.message}`);
  }
}
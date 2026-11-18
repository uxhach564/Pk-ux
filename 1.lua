

-- ==================== 武器+配件统一刷新系统（完整保留原逻辑） ====================

-- 你的原有全局变量（全部保留）
-- ============ ★ 功耗优化：全局缓存 ============
-- ★ 清理旧版缓存，防止残留污染
_G.__baseWeaponIDCache = nil
_G.Mytimer_ticker = _G.Mytimer_ticker or require("common.time_ticker")

_G.__perf = _G.__perf or {
    partsInited      = {},   -- [avatarid] = true
    attachStamp      = {},   -- [key] = lastTime
    petStamp         = 0,
    petId            = 0,
    cfgReadAt        = 0,
    killReadAt       = 0,
    playerRefreshStamp = 0,
    dataMgrScanAt    = 0,
}

_G.equip_weapon_avatar = nil
_G.g_parts = nil
_G.g_parts_subtype = nil
_G.lastAppliedSkin = {}
_G.lastAppliedAttachments = {}
_G.lastAppliedAttachmentFp = {}
_G.skinDownloadCache = {}
_G.skinHasAttachmentSkinsCache = {}



local possiblePaths = {
    "/storage/emulated/0/Android/obb/com.tencent.ig/wumingking.h",     
    "/storage/emulated/0/Android/obb/com.pubg.krmobile/wumingking.h",   
    "/storage/emulated/0/Android/obb/com.vng.pubgmobile/wumingking.h",
    "/storage/emulated/0/Android/obb/com.rekoo.pubgm/wumingking.h",
    "/storage/emulated/0/Android/obb/com.pubg.imobile/wumingking.h",
}

-- ★★★ 新增：获取当前游戏包名（多路兜底，优先返回真实包名） ★★★
function _G.GetCurrentGamePackage()
    local ok, pkg

    ok, pkg = pcall(function() return slua_GameFrontendHUD:GetPackageName() end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function() return Client.GetPackageName() end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function()
        local GPS = import("GameplayStatics")
        return GPS.GetPackageName()
    end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function()
        local act = slua_GameFrontendHUD:GetActivity()
        return act and act:getPackageName()
    end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function()
        return slua_GameFrontendHUD.PackageName or slua_GameFrontendHUD.packageName
    end)
    if ok and pkg and pkg ~= "" then return pkg end

    return nil
end

-- ★★★ 新增：按当前包名得到 wumingking.h 路径，拿不到则返回 nil ★★★
function _G.GetCurrentWumingPath()
    local pkg = _G.GetCurrentGamePackage and _G.GetCurrentGamePackage()
    if not pkg then return nil end
    local p = "/storage/emulated/0/Android/obb/" .. pkg .. "/wumingking.h"
    -- "a" 模式：目录存在则创建/打开成功，目录不存在则失败
    local ok, f = pcall(io.open, p, "a")
    if ok and f then
        f:close()
        return p
    end
    return nil
end

local lastConfig = {}
_G.lastConfig = lastConfig

-- ==================== 全局变量初始化 ====================
_G.HairSkin = _G.HairSkin or 0
_G.SuitSkin = _G.SuitSkin or 0
_G.HeadShapeSkin = _G.HeadShapeSkin or 0
-- ==================== 功能开关 ====================
_G.EnableDeadBoxSkin = _G.EnableDeadBoxSkin or true   -- 默认开启
-- ==================== 天气配置 ====================
_G.WeatherMode = _G.WeatherMode or 0  -- 默认：无天气
-- ==================== 广角配置 ====================
_G.ConfigFOVEnable = _G.ConfigFOVEnable or false   -- 广角开关，默认关闭
_G.ConfigFOV = _G.ConfigFOV or 90                  -- 广角度数（开关关着时不生效）


_G.HatSkin = _G.HatSkin or 0
_G.FaceSkin = _G.FaceSkin or 0
_G.MaskSkin = _G.MaskSkin or 0
_G.GlovesSkin = _G.GlovesSkin or 0
_G.PantSkin = _G.PantSkin or 0
_G.ShoeSkin = _G.ShoeSkin or 0
_G.ParachuteSkin = _G.ParachuteSkin or 1401469
_G.GliderSkin = _G.GliderSkin or 4151133
_G.Backpack1Skin = _G.Backpack1Skin or 0
_G.Backpack2Skin = _G.Backpack2Skin or 0
_G.Backpack3Skin = _G.Backpack3Skin or 0
_G.Backpack4Skin = _G.Backpack4Skin or 0
_G.Backpack5Skin = _G.Backpack5Skin or 0
_G.Backpack6Skin = _G.Backpack6Skin or 0
_G.Helmet1Skin = _G.Helmet1Skin or 0
_G.Helmet2Skin = _G.Helmet2Skin or 0
_G.Helmet3Skin = _G.Helmet3Skin or 0
_G.Helmet4Skin = _G.Helmet4Skin or 0
_G.Helmet5Skin = _G.Helmet5Skin or 0
_G.Helmet6Skin = _G.Helmet6Skin or 0
-- 防弹衣皮肤（缺少的部分）
_G.Armor1Skin = _G.Armor1Skin or 0
_G.Armor2Skin = _G.Armor2Skin or 0
_G.Armor3Skin = _G.Armor3Skin or 0
_G.Armor4Skin = _G.Armor4Skin or 0
_G.Armor5Skin = _G.Armor5Skin or 0
_G.Armor6Skin = _G.Armor6Skin or 0

-- 宠物皮肤配置
_G.PetSkinMap = _G.PetSkinMap or {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044,
    50045, -- 小兔子伙伴
50046, -- 咒骸拳击熊伙伴
}
_G.PetSkinMapIndex = _G.PetSkinMapIndex or 1
_G.LastAppliedPet = _G.LastAppliedPet or 0

-- 武器皮肤自由模式存储
_G.WeaponSkinID = _G.WeaponSkinID or {}

_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}
_G.skinIdCache3 = _G.skinIdCache3 or {}
_G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
_G.CurrentEquipVehicleID = _G.CurrentEquipVehicleID or 0

-- ==================== 死亡盒子变量 ====================
_G.DeadBoxSkins = _G.DeadBoxSkins or {}
_G.AlreadyChangedSet = _G.AlreadyChangedSet or {}


-- 装备槽位类型
_G.CustSlotType = _G.CustSlotType or {
    NONE = 0, HeadEquipemtSlot = 1, HairEquipemtSlot = 2, HatEquipemtSlot = 3,
    FaceEquipemtSlot = 4, ClothesEquipemtSlot = 5, PantsEquipemtSlot = 6,
    ShoesEquipemtSlot = 7, BackpackEquipemtSlot = 8, HelmetEquipemtSlot = 9,
    ArmorEquipemtSlot = 10, ParachuteEquipemtSlot = 11, GlassEquipemtSlot = 12,
    NightVisionEquipemtSlot = 13, BeardEquipemtSlot = 14, GlideEquipemtSlot = 15,
    HandEffectEquipemtSlot = 16, BackPack_PendantSlot = 17, MechaChestSlot = 18,
    MechaArmSlot = 19, MechaLegSlot = 20, MechaInnerSuitSlot = 21,
    FootEffectEquipemtSlot = 22, MaxSlotNum = 23, VehicleCut = 24,
    UnderClothSlot = 25, UnderPantsSlot = 26, SimpleSlotMax = 27, MAX = 28
}

-- ==================== 下载函数 ====================
local function download_item(id)
    if not PufferManager or not PufferConst then return end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {id})
    if state ~= PufferConst.ENUM_DownloadState.Done then
        PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {id})
    end
end
_G.download_item = download_item

-- ==================== 角色装备应用函数 ====================
function _G.equip_character_avatar(uCharacter)
    if not uCharacter or not slua.isValid(uCharacter) or not uCharacter.AvatarComponent2 then return end
    
    local BackpackUtils = import("BackpackUtils")
    if not BackpackUtils then return end
    
    local ApplyData = uCharacter.AvatarComponent2.NetAvatarData and uCharacter.AvatarComponent2.NetAvatarData.SlotSyncData
    if not ApplyData or not slua.isValid(ApplyData) then return end
    
    local function setMakeSkin(ApplyDataIdx, currentItemId, targetSkinId, ApplyEquipSlot)
    if targetSkinId ~= nil then
        local equipment = ApplyData:Get(ApplyDataIdx)
        if equipment and equipment.SlotID == ApplyEquipSlot then
            if targetSkinId == 0 then
                -- ★ 套装模式下，强制卸下 6/7
                if _G.Wumingking and _G.Wumingking.GetSuit and _G.Wumingking.GetSuit() > 0
                   and (ApplyEquipSlot == 6 or ApplyEquipSlot == 7) then
                    if equipment.ItemId ~= 0 then
                        equipment.ItemId = 0
                        ApplyData:Set(ApplyDataIdx, equipment)
                        uCharacter.AvatarComponent2:OnRep_BodySlotStateChanged()
                    end
                end
                return
            end
                if equipment.ItemId ~= targetSkinId then
                    if not _G.skinIdCache[targetSkinId] then
                        pcall(_G.download_item, targetSkinId)
                        _G.skinIdCache[targetSkinId] = true
                    end
                    equipment.ItemId = targetSkinId
                    ApplyData:Set(ApplyDataIdx, equipment)
                    uCharacter.AvatarComponent2:OnRep_BodySlotStateChanged()
                end
            end
        end
    end
    
    -- 确保滑翔翼、降落伞、头饰、口罩、眼罩、头发槽位存在
local checkSlots = {
    _G.CustSlotType.GlideEquipemtSlot,     -- 15 (滑翔翼)
    _G.CustSlotType.ParachuteEquipemtSlot, -- 11 (降落伞)
    _G.CustSlotType.HatEquipemtSlot,       -- 3  (头饰)
    _G.CustSlotType.FaceEquipemtSlot,      -- 4  (口罩/面饰)
    _G.CustSlotType.GlassEquipemtSlot,     -- 12 (眼罩)
    _G.CustSlotType.HairEquipemtSlot,      -- 2  (头发)
    _G.CustSlotType.HandEffectEquipemtSlot,-- 16 (手套) ← 新增
}
local slotFound = {}
for i = 0, ApplyData:Num() - 1 do
    local equipment = ApplyData:Get(i)
    if equipment then
        slotFound[equipment.SlotID] = true
    end
end
for _, slotID in ipairs(checkSlots) do
    if not slotFound[slotID] then
        ApplyData:Add({ SlotID = slotID, ItemId = 0 })
    end
end
    
    -- 应用所有装备皮肤
    for i = 0, ApplyData:Num() - 1 do
        local equipment = ApplyData:Get(i)
        local currentItemId = equipment.ItemId
        
        setMakeSkin(i, currentItemId, _G.SuitSkin, _G.CustSlotType.ClothesEquipemtSlot)
        
        -- ★ 恢复：头发与头饰同时应用
        setMakeSkin(i, currentItemId, _G.HairSkin, _G.CustSlotType.HairEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.HatSkin, _G.CustSlotType.HatEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.FaceSkin, _G.CustSlotType.FaceEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.MaskSkin, _G.CustSlotType.GlassEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.GlovesSkin, _G.CustSlotType.HandEffectEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.PantSkin, _G.CustSlotType.PantsEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.ShoeSkin, _G.CustSlotType.ShoesEquipemtSlot)
        
        -- 背包
        if equipment.SlotID == _G.CustSlotType.BackpackEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentBagLevel(equipment.AdditionalItemID) or 1
            local targetBagSkin = 0
            if nItemLevel == 1 then targetBagSkin = _G.Backpack1Skin
            elseif nItemLevel == 2 then targetBagSkin = _G.Backpack2Skin
            elseif nItemLevel == 3 then targetBagSkin = _G.Backpack3Skin
            elseif nItemLevel == 4 then targetBagSkin = _G.Backpack4Skin
            elseif nItemLevel == 5 then targetBagSkin = _G.Backpack5Skin
            elseif nItemLevel == 6 then targetBagSkin = _G.Backpack6Skin
            end
            setMakeSkin(i, currentItemId, targetBagSkin, _G.CustSlotType.BackpackEquipemtSlot)
        end
        
        -- 头盔
        if equipment.SlotID == _G.CustSlotType.HelmetEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentHelmetLevel(equipment.AdditionalItemID) or 1
            local targetHelmetSkin = 0
            if nItemLevel == 1 then targetHelmetSkin = _G.Helmet1Skin
            elseif nItemLevel == 2 then targetHelmetSkin = _G.Helmet2Skin
            elseif nItemLevel == 3 then targetHelmetSkin = _G.Helmet3Skin
            elseif nItemLevel == 4 then targetHelmetSkin = _G.Helmet4Skin
            elseif nItemLevel == 5 then targetHelmetSkin = _G.Helmet5Skin
            elseif nItemLevel == 6 then targetHelmetSkin = _G.Helmet6Skin
            end
            setMakeSkin(i, currentItemId, targetHelmetSkin, _G.CustSlotType.HelmetEquipemtSlot)
        end
        
        -- 防弹衣
        if equipment.SlotID == _G.CustSlotType.ArmorEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentArmorLevel(equipment.AdditionalItemID) or 1
            local targetArmorSkin = 0
            if nItemLevel == 1 then targetArmorSkin = _G.Armor1Skin
            elseif nItemLevel == 2 then targetArmorSkin = _G.Armor2Skin
            elseif nItemLevel == 3 then targetArmorSkin = _G.Armor3Skin
            elseif nItemLevel == 4 then targetArmorSkin = _G.Armor4Skin
            elseif nItemLevel == 5 then targetArmorSkin = _G.Armor5Skin
            elseif nItemLevel == 6 then targetArmorSkin = _G.Armor6Skin
            end
            setMakeSkin(i, currentItemId, targetArmorSkin, _G.CustSlotType.ArmorEquipemtSlot)
        end
        
        -- ★★★ 降落伞/滑翔翼：0 强制用默认值（100% 安装） ★★★
        local gliderApply = (_G.GliderSkin and _G.GliderSkin > 0) and _G.GliderSkin or 4151133
        local parachuteApply = (_G.ParachuteSkin and _G.ParachuteSkin > 0) and _G.ParachuteSkin or 1401469
        setMakeSkin(i, currentItemId, gliderApply, _G.CustSlotType.GlideEquipemtSlot)
        setMakeSkin(i, currentItemId, parachuteApply, _G.CustSlotType.ParachuteEquipemtSlot)
    end
end

-- ==================== 武器基础ID映射 ====================
_G.WeaponNameToID = {
    -- ========== 突击步枪 ==========
    AKM = 101001,
    M16A4 = 101002,
    SCAR = 101003,
    M416 = 101004,
    GROZA = 101005,
    AUG = 101006,
    QBZ = 101007,
    M762 = 101008,
    Mk47 = 101009,
    G36C = 101010,
    HoneyPot = 101012,
    FAMAS = 101100,
    ASM = 101101,
    ACE32 = 101102,
    
    -- ========== 冲锋枪 ==========
    UZI = 102001,
    UMP = 102002,
    VECTOR = 102003,
    THOMPSON = 102004,
    BIZON = 102005,
    MP5K = 102007,
    JS9 = 102008,
    P90 = 102105,
    
    -- ========== 狙击枪/射手步枪 ==========
    K98 = 103001,
    M24 = 103002,
    AWM = 103003,
    SKS = 103004,
    VSS = 103005,
    Mini14 = 103006,
    MK14 = 103007,
    Win94 = 103008,
    M1Garand = 103103,
    SLR = 103009,
    QBU = 103010,
    Mosin = 103011,
    AMR = 103012,
    Mk12 = 103100,
    DSR = 103102,
    
    -- ========== 霰弹枪 ==========
    S686 = 104001,
    S1897 = 104002,
    S12K = 104003,
    DBS = 104004,
    M1014 = 104101,
    NS2000 = 104102,
    
    -- ========== 轻机枪 ==========
    M249 = 105001,
    DP28 = 105002,
    MG3 = 105010,
    
    -- ========== 近战 ==========
    PAN = 108004,
    DAGGER = 108005,
    Machete = 108001,
}

_G.WeaponIDSets = {
    -- ========== 突击步枪 ==========
    M416 = {[101004]=true, [1010041]=true, [1010042]=true, [1010043]=true, [1010044]=true, [1010045]=true, [1010046]=true, [1010047]=true, [1010049]=true},
    AKM = {[101001]=true, [1010011]=true, [1010012]=true, [1010013]=true, [1010014]=true, [1010015]=true, [1010016]=true, [1010017]=true, [1010019]=true},
    SCAR = {[101003]=true, [1010031]=true, [1010032]=true, [1010033]=true, [1010034]=true, [1010035]=true, [1010036]=true, [1010037]=true, [1010039]=true},
    M762 = {[101008]=true, [1010081]=true, [1010082]=true, [1010083]=true, [1010084]=true, [1010085]=true, [1010086]=true, [1010087]=true, [1010089]=true},
    GROZA = {[101005]=true, [1010051]=true, [1010052]=true, [1010053]=true, [1010054]=true, [1010055]=true, [1010056]=true, [1010057]=true, [1010059]=true},
    AUG = {[101006]=true, [1010061]=true, [1010062]=true, [1010063]=true, [1010064]=true, [1010065]=true, [1010066]=true, [1010067]=true},
    QBZ = {[101007]=true, [1010071]=true, [1010072]=true, [1010073]=true, [1010074]=true, [1010075]=true, [1010076]=true, [1010077]=true},
    M16A4 = {[101002]=true, [1010021]=true, [1010022]=true, [1010023]=true, [1010024]=true, [1010025]=true},
    FAMAS = {[101100]=true, [1011001]=true, [1011002]=true, [1011003]=true, [1011004]=true, [1011005]=true, [1011006]=true, [1011007]=true},
    ACE32 = {[101102]=true, [1011021]=true, [1011022]=true, [1011023]=true, [1011024]=true, [1011025]=true, [1011026]=true, [1011027]=true},
    ASM = {[101101]=true, [1011011]=true, [1011012]=true, [1011013]=true, [1011014]=true, [1011015]=true, [1011016]=true, [1011017]=true},
    Mk47 = {[101009]=true, [1010091]=true, [1010092]=true, [1010093]=true, [1010094]=true, [1010095]=true, [1010096]=true, [1010097]=true, [1010099]=true},
    G36C = {[101010]=true, [1010101]=true, [1010102]=true, [1010103]=true, [1010104]=true, [1010105]=true, [1010106]=true, [1010107]=true, [1010109]=true},
    HoneyPot = {[101012]=true, [1010121]=true, [1010122]=true, [1010123]=true, [1010124]=true, [1010125]=true, [1010126]=true, [1010127]=true, [1010129]=true},
    
    -- ========== 冲锋枪 ==========
    UMP = {[102002]=true, [1020021]=true, [1020022]=true, [1020023]=true, [1020024]=true, [1020025]=true, [1020029]=true},
    VECTOR = {[102003]=true, [1020031]=true, [1020032]=true, [1020033]=true, [1020034]=true, [1020035]=true, [1020036]=true, [1020037]=true},
    UZI = {[102001]=true, [1020011]=true, [1020012]=true, [1020013]=true, [1020014]=true, [1020015]=true},
    THOMPSON = {[102004]=true, [1020041]=true, [1020042]=true, [1020043]=true, [1020044]=true, [1020045]=true},
    BIZON = {[102005]=true, [1020051]=true, [1020052]=true, [1020053]=true, [1020054]=true, [1020055]=true, [1020059]=true},
    P90 = {[102105]=true, [1021051]=true, [1021052]=true, [1021053]=true, [1021054]=true, [1021055]=true, [1021056]=true, [1021057]=true},
    MP5K = {[102007]=true, [1020071]=true, [1020072]=true, [1020073]=true, [1020074]=true, [1020075]=true, [1020076]=true, [1020077]=true, [1020079]=true},
    JS9 = {[102008]=true, [1020081]=true, [1020082]=true, [1020083]=true, [1020084]=true, [1020085]=true, [1020086]=true, [1020087]=true, [1020089]=true},
    
    -- ========== 狙击枪 ==========
    AWM = {[103003]=true, [1030031]=true, [1030032]=true, [1030033]=true, [1030034]=true, [1030035]=true, [1030036]=true, [1030037]=true, [1030039]=true},
    M24 = {[103002]=true, [1030021]=true, [1030022]=true, [1030023]=true, [1030024]=true, [1030025]=true, [1030026]=true, [1030027]=true},
    K98 = {[103001]=true, [1030011]=true, [1030012]=true, [1030013]=true, [1030014]=true, [1030015]=true, [1030019]=true},
    MK14 = {[103007]=true, [1030071]=true, [1030072]=true, [1030073]=true, [1030074]=true, [1030075]=true, [1030076]=true, [1030077]=true},
    AMR = {[103012]=true, [1030121]=true, [1030122]=true, [1030123]=true, [1030124]=true, [1030125]=true, [1030126]=true, [1030127]=true},
    DSR = {[103102]=true, [1031021]=true, [1031022]=true, [1031023]=true, [1031024]=true, [1031025]=true, [1031026]=true, [1031027]=true, [1031029]=true},
    SKS = {[103004]=true, [1030041]=true, [1030042]=true, [1030043]=true, [1030044]=true, [1030045]=true, [1030046]=true, [1030047]=true, [1030049]=true},
    Mini14 = {[103006]=true, [1030061]=true, [1030062]=true, [1030063]=true, [1030064]=true, [1030065]=true, [1030066]=true, [1030067]=true, [1030069]=true},
    VSS = {[103005]=true, [1030051]=true, [1030052]=true, [1030053]=true, [1030054]=true, [1030055]=true, [1030056]=true, [1030057]=true, [1030059]=true},
    Win94 = {[103008]=true, [1030081]=true, [1030082]=true, [1030083]=true, [1030084]=true, [1030085]=true, [1030086]=true, [1030087]=true, [1030089]=true},
    M1Garand = {[103103]=true},
    SLR = {[103009]=true, [1030091]=true, [1030092]=true, [1030093]=true, [1030094]=true, [1030095]=true, [1030096]=true, [1030097]=true, [1030099]=true},
    QBU = {[103010]=true, [1030101]=true, [1030102]=true, [1030103]=true, [1030104]=true, [1030105]=true, [1030106]=true, [1030107]=true, [1030109]=true},
    Mosin = {[103011]=true, [1030111]=true, [1030112]=true, [1030113]=true, [1030114]=true, [1030115]=true, [1030116]=true, [1030117]=true, [1030119]=true},
    Mk12 = {[103100]=true, [1031001]=true, [1031002]=true, [1031003]=true, [1031004]=true, [1031005]=true, [1031006]=true, [1031007]=true, [1031009]=true},
    
    -- ========== 霰弹枪 ==========
    S686 = {[104001]=true, [1040011]=true, [1040012]=true, [1040013]=true, [1040014]=true, [1040015]=true, [1040016]=true, [1040017]=true, [1040019]=true},
    S1897 = {[104002]=true, [1040021]=true, [1040022]=true, [1040023]=true, [1040024]=true, [1040025]=true, [1040026]=true, [1040027]=true, [1040029]=true},
    S12K = {[104003]=true, [1040031]=true, [1040032]=true, [1040033]=true, [1040034]=true, [1040035]=true, [1040036]=true, [1040037]=true, [1040039]=true},
    DBS = {[104004]=true, [1040041]=true, [1040042]=true, [1040043]=true, [1040044]=true, [1040045]=true, [1040046]=true, [1040047]=true, [1040049]=true},
    M1014 = {[104101]=true, [1041011]=true, [1041012]=true, [1041013]=true, [1041014]=true, [1041015]=true, [1041016]=true, [1041017]=true, [1041019]=true},
    NS2000 = {[104102]=true, [1041021]=true, [1041022]=true, [1041023]=true, [1041024]=true, [1041025]=true, [1041026]=true, [1041027]=true, [1041029]=true},
    
    -- ========== 轻机枪 ==========
    M249 = {[105001]=true, [1050011]=true, [1050012]=true, [1050013]=true, [1050014]=true, [1050015]=true, [1050016]=true, [1050017]=true},
    DP28 = {[105002]=true, [1050021]=true, [1050022]=true, [1050023]=true, [1050024]=true, [1050025]=true, [1050026]=true, [1050027]=true, [1050029]=true},
    MG3 = {[105010]=true, [1050101]=true, [1050102]=true, [1050103]=true, [1050104]=true, [1050105]=true, [1050106]=true, [1050107]=true, [1050109]=true},
    
    -- ========== 近战 ==========
    PAN = {[108004]=true, [1080040]=true, [1080041]=true, [1080042]=true, [1080043]=true, [1080044]=true, [1080049]=true},
    DAGGER = {[108005]=true, [1080050]=true, [1080051]=true, [1080059]=true},
    Machete = {[108001]=true, [1080010]=true, [1080011]=true, [1080019]=true},
}

-- ★ getBaseWeaponID 拆分原始逻辑（无缓存，完全等同于原版）
local function _getBaseWeaponID_raw(weaponID)
    if not weaponID then return nil end
    
    for weaponType, idSet in pairs(_G.WeaponIDSets) do
        if idSet[weaponID] then
            local minID = math.huge
            for id in pairs(idSet) do
                if id < minID then minID = id end
            end
            return minID
        end
    end
    
-- 皮肤ID范围自动识别（补全）
if weaponID >= 1101004001 and weaponID <= 1101004246 then return 101004 end  -- M416
if weaponID >= 1101001001 and weaponID <= 1101001999 then return 101001 end  -- AKM
if weaponID >= 1101003001 and weaponID <= 1101003999 then return 101003 end  -- SCAR
if weaponID >= 1101008001 and weaponID <= 1101008999 then return 101008 end  -- M762
if weaponID >= 1101002001 and weaponID <= 1101002999 then return 101002 end  -- M16A4
if weaponID >= 1101005001 and weaponID <= 1101005999 then return 101005 end  -- GROZA
if weaponID >= 1101006001 and weaponID <= 1101006999 then return 101006 end  -- AUG
if weaponID >= 1101007001 and weaponID <= 1101007999 then return 101007 end  -- QBZ
if weaponID >= 1101009001 and weaponID <= 1101009999 then return 101009 end  -- Mk47
if weaponID >= 1101010001 and weaponID <= 1101010999 then return 101010 end  -- G36C
if weaponID >= 1101012001 and weaponID <= 1101012999 then return 101012 end  -- HoneyPot
if weaponID >= 1101100001 and weaponID <= 1101100999 then return 101100 end  -- FAMAS
if weaponID >= 1101101001 and weaponID <= 1101101999 then return 101101 end  -- ASM
if weaponID >= 1101102001 and weaponID <= 1101102999 then return 101102 end  -- ACE32

if weaponID >= 1102001001 and weaponID <= 1102001999 then return 102001 end  -- UZI
if weaponID >= 1102002001 and weaponID <= 1102002999 then return 102002 end  -- UMP
if weaponID >= 1102003001 and weaponID <= 1102003999 then return 102003 end  -- VECTOR
if weaponID >= 1102004001 and weaponID <= 1102004999 then return 102004 end  -- THOMPSON
if weaponID >= 1102005001 and weaponID <= 1102005999 then return 102005 end  -- BIZON
if weaponID >= 1102007001 and weaponID <= 1102007999 then return 102007 end  -- MP5K
if weaponID >= 1102008001 and weaponID <= 1102008999 then return 102008 end  -- JS9
if weaponID >= 1102105001 and weaponID <= 1102105999 then return 102105 end  -- P90

if weaponID >= 1103001001 and weaponID <= 1103001999 then return 103001 end  -- K98
if weaponID >= 1103002001 and weaponID <= 1103002999 then return 103002 end  -- M24
if weaponID >= 1103003001 and weaponID <= 1103003999 then return 103003 end  -- AWM
if weaponID >= 1103004001 and weaponID <= 1103004999 then return 103004 end  -- SKS
if weaponID >= 1103005001 and weaponID <= 1103005999 then return 103005 end  -- VSS
if weaponID >= 1103006001 and weaponID <= 1103006999 then return 103006 end  -- Mini14
if weaponID >= 1103007001 and weaponID <= 1103007999 then return 103007 end  -- MK14
if weaponID >= 1103008001 and weaponID <= 1103008999 then return 103008 end  -- Win94
if weaponID >= 1103103001 and weaponID <= 1103103999 then return 103103 end
if weaponID >= 1103009001 and weaponID <= 1103009999 then return 103009 end  -- SLR
if weaponID >= 1103010001 and weaponID <= 1103010999 then return 103010 end  -- QBU
if weaponID >= 1103011001 and weaponID <= 1103011999 then return 103011 end  -- Mosin
if weaponID >= 1103012001 and weaponID <= 1103012999 then return 103012 end  -- AMR
if weaponID >= 1103100001 and weaponID <= 1103100999 then return 103100 end  -- Mk12
if weaponID >= 1103102001 and weaponID <= 1103102999 then return 103102 end  -- DSR

if weaponID >= 1104001001 and weaponID <= 1104001999 then return 104001 end  -- S686
if weaponID >= 1104002001 and weaponID <= 1104002999 then return 104002 end  -- S1897
if weaponID >= 1104003001 and weaponID <= 1104003999 then return 104003 end  -- S12K
if weaponID >= 1104004001 and weaponID <= 1104004999 then return 104004 end  -- DBS
if weaponID >= 1104101001 and weaponID <= 1104101999 then return 104101 end  -- M1014
if weaponID >= 1104102001 and weaponID <= 1104102999 then return 104102 end  -- NS2000

if weaponID >= 1105001001 and weaponID <= 1105001999 then return 105001 end  -- M249
if weaponID >= 1105002001 and weaponID <= 1105002999 then return 105002 end  -- DP28
if weaponID >= 1105010001 and weaponID <= 1105010999 then return 105010 end  -- MG3

if weaponID >= 1108001001 and weaponID <= 1108001999 then return 108001 end  -- Machete
if weaponID >= 1108004001 and weaponID <= 1108004999 then return 108004 end  -- PAN
if weaponID >= 1108005001 and weaponID <= 1108005999 then return 108005 end  -- Dagger

    -- ★★★ 修复：近战7位变体精确映射（之前漏掉导致判定混乱）★★★
    if weaponID >= 1080011 and weaponID <= 1080019 then return 108001 end
    if weaponID >= 1080041 and weaponID <= 1080049 then return 108004 end
    if weaponID >= 1080051 and weaponID <= 1080059 then return 108005 end
    
    return weaponID
end

-- ★ 对外接口：无缓存，等同于原版行为
function _G.getBaseWeaponID(weaponID)
    return _getBaseWeaponID_raw(weaponID)
end





-- ==================== 自动生成配件品质后缀 ====================

_G.WeaponSkinPack = {
    -- ========== AKM ==========
    AKM = {
        [1] = { main = 1101001213, attachments = {} }, -- 星海提督-AKM(8级)
        [2] = { main = 1101001174, attachments = {} }, -- 部落之王-AKM(8级)
        [3] = { main = 1101001242, attachments = {} }, -- 决胜之日-AKM(8级)
        [4] = { main = 1101001256, attachments = {} }, -- 光暗圣殿（金羽）-AKM(7级)
        [5] = { main = 1101001249, attachments = {} }, -- 光暗圣殿（神月）-AKM(7级)
        [6] = { main = 1101001265, attachments = {} }, -- 沙影神国-AKM(8级)
        [7] = { main = 1101001276, attachments = {} }, -- 律动光影-AKM(8级)
        [8] = { main = 1101001103, attachments = {} }, -- 积木龙骨-AKM(7级)
        [9] = { main = 1101001089, attachments = {} }, -- 冰霜核心-AKM(7级)
    },

    -- ========== M16A4 ==========
    M16A4 = {
        [1] = { main = 1101002081, attachments = {} },
        [2] = { main = 1101002156, attachments = {} }, -- 甜蜜囚笼-M16A4(7级)
        [3] = { main = 1101002149, attachments = {} }, -- 翡翠流云-M16A4(5级)
        [4] = { main = 1101002142, attachments = {} }, -- PUBG MOBILE × G-DRAGON - M16A4(5级)
        [5] = { main = 1101002133, attachments = {} }, -- 机械哥斯拉-M16A4(5级)
        [6] = { main = 1101002125, attachments = {} }, -- 冰封灵魂-M16A4(5级)
        [7] = { main = 1101002117, attachments = {} }, -- 天境神灯-M16A4(5级)
    },

    -- ========== SCAR ==========
    SCAR = {
        [1] = { main = 1101003227, attachments = {} }, -- 凤曜琼华-SCAR-L(8级)
        [2] = { main = 1101003219, attachments = {} }, -- 御灵魂契-SCAR-L(7级)
        [3] = { main = 1101003208, attachments = {} }, -- 梦幻奇缘-SCAR-L(7级)
        [4] = { main = 1101003195, attachments = {} }, -- 霓虹天后-SCAR-L(7级)
        [5] = { main = 1101003167, attachments = {} }, -- 血魂魔皇-SCAR-L(8级)
        [6] = { main = 1101003146, attachments = {} }, -- 邪能植物-SCAR-L(8级)
        [7] = { main = 1101003119, attachments = {} }, -- 魔力结晶-SCAR-L(7级)
        [8] = { main = 1101003099, attachments = {} }, -- 诡秘之夜-SCAR-L(7级)
        [9] = { main = 1101003080, attachments = {} }, -- 翌日行动-SCAR-L(7级)
        [10] = { main = 1101003070, attachments = {} }, -- 魔法南瓜-SCAR-L(7级)
    },

    -- ========== M416 ==========
    M416 = {
        [1] = { main = 1101004046, attachments = {} }, -- 冰霜核心-M416(7级)
        [2] = { main = 1101004062, attachments = {} }, -- 愚人小丑-M416(7级)
        [3] = { main = 1101004078, attachments = {} }, -- 异域游荡者-M416(7级)
        [4] = { main = 1101004086, attachments = {} }, -- 萌龙咆哮-M416(7级)
        [5] = { main = 1101004098, attachments = {} }, -- 野性呼唤-M416(7级)
        [6] = { main = 1101004138, attachments = {} }, -- 科技核心-M416(7级)
        [7] = { main = 1101004163, attachments = {} }, -- 潮鸣宫廷-M416(8级)
        [8] = { main = 1101004201, attachments = {} }, -- 武魂宗师-M416(8级)
        [9] = { main = 1101004209, attachments = {} }, -- 庇护之潮-M416(8级)
        [10] = { main = 1101004218, attachments = {} }, -- 机魂忍神-M416(8级)
        [11] = { main = 1101004226, attachments = {} }, -- 封印幽冥-M416(8级)
        [12] = { main = 1101004236, attachments = {} }, -- 虎啸丹青-M416(8级)
        [13] = { main = 1101004246, attachments = {} }, -- 赤霄神剑-M416(8级)
        [14] = { main = 1101004034, attachments = {} }, -- 黄金时代-M416
    },

    -- ========== GROZA ==========
    GROZA = {
        [1] = { main = 1101005098, attachments = {} }, -- 红莲哥斯拉-Groza(7级)
        [2] = { main = 1101005052, attachments = {} }, -- 冥河烈焰-Groza(7级)
        [3] = { main = 1101005038, attachments = {} }, -- 两面宿傩-Groza(7级)
        [4] = { main = 1101005043, attachments = {} }, -- 绚烂之战-Groza(5级)
        [5] = { main = 1101005090, attachments = {} }, -- 古神蚀刻-GROZA(5级)
        [6] = { main = 1101005082, attachments = {} }, -- 幽冥夜歌-Groza(5级)
    },

    -- ========== AUG ==========
    AUG = {
        [1] = { main = 1101006085, attachments = {} }, -- 罪恶玫瑰-AUG(8级)
        [2] = { main = 1101006075, attachments = {} }, -- 破军狂鸣-AUG(7级)
        [3] = { main = 1101006062, attachments = {} }, -- 弃誓冰灵-AUG(8级)
        [4] = { main = 1101006033, attachments = {} }, -- 流浪马戏团-AUG(5级)
    },

    -- ========== QBZ ==========
    QBZ = {
        [1] = { main = 1101007062, attachments = {} },
        [2] = { main = 1101007071, attachments = {} }, -- 灵蛟曼舞-QBZ(7级)
        [3] = { main = 1101007046, attachments = {} }, -- 瑰绮灵姬-QBZ(7级)
        [4] = { main = 1101007078, attachments = {} }, -- 冰冷魅惑-QBZ(5级)
    },

    -- ========== M762 ==========
    M762 = {
        [1] = { main = 1101008163, attachments = {} }, -- 灵阁魔剪-M762(7级)
        [2] = { main = 1101008154, attachments = {} }, -- 铂金骸骨-M762(8级)
        [3] = { main = 1101008146, attachments = {} }, -- 森白骸骨-M762(8级)
        [4] = { main = 1101008136, attachments = {} }, -- 琉璃仙灵-M762(7级)
        [5] = { main = 1101008079, attachments = {} }, -- 乖张怪客-M762(7级)
        [6] = { main = 1101008061, attachments = {} }, -- 精密杀戮-M762(7级)
        [7] = { main = 1101008104, attachments = {} }, -- 星云机械-M762(8级)
        [8] = { main = 1101008126, attachments = {} }, -- 龙女魔后-M762(7级)
        [9] = { main = 1101008116, attachments = {} }, -- 梅西绿茵传奇M762(7级)
        [10] = { main = 1101008051, attachments = {} }, -- 浪漫乐章-M762(7级)
    },

    -- ========== Mk47 ==========
    Mk47 = {
        [1] = { main = 1101009019, attachments = {} },
        [2] = { main = 1101009022, attachments = {} }, -- S28-Mk47
        [3] = { main = 1101009013, attachments = {} }, -- 混沌锁链-Mk47
    },

    -- ========== G36C ==========
    G36C = {
        [1] = { main = 1101010029, attachments = {} }, -- 上古能源-G36C(5级)
        [2] = { main = 1101010024, attachments = {} }, -- 朋克先锋-G36C
    },

    -- ========== HoneyPot ==========
    HoneyPot = {
        [1] = { main = 1101012033, attachments = {} },
        [2] = { main = 1101012018, attachments = {} }, -- 音乐旋律-蜜獾(5级)
        [3] = { main = 1101012024, attachments = {} }, -- 万次郎-蜜獾(5级)
        [4] = { main = 1101012009, attachments = {} }, -- 极耀炫彩-蜜獾(5级)
    },

    -- ========== FAMAS ==========
    FAMAS = {
        [1] = { main = 1101100012, attachments = {} },
        [2] = { main = 1101100018, attachments = {} }, -- 赛博幻影-FAMAS(5级)
    },

    -- ========== ASM ==========
    ASM = {
        [1] = { main = 1101101007, attachments = {} },
    },

    -- ========== ACE32 ==========
    ACE32 = {
        [1] = { main = 1101102049, attachments = {} }, -- 浮梦蝶语-ACE32(8级)
        [2] = { main = 1101102007, attachments = {} }, -- 终极对撞-ACE32(7级)
        [3] = { main = 1101102017, attachments = {} }, -- 神庭冰棘-ACE32(7级)
        [4] = { main = 1101102025, attachments = {} }, -- 传奇海怪号-ACE32(8级)
    },

    -- ========== UMP ==========
    UMP = {
        [1] = { main = 1102002136, attachments = {} }, -- 水晶冰刺-UMP45(7级)
        [2] = { main = 1102002424, attachments = {} }, -- 噬魂凝视-UMP45(7级)
        [3] = { main = 1102002438, attachments = {} }, -- 无间双子-UMP45(8级)
        [4] = { main = 1102002446, attachments = {} }, -- 赤陨双生-UMP45(8级)
    },

    -- ========== UZI ==========
    UZI = {
        [1] = { main = 1102001120, attachments = {} }, -- 冰晶神锤-UZI(8级)
        [2] = { main = 1102001130, attachments = {} }, -- 烈焰枷锁-UZI(7级)
    },

    -- ========== VECTOR ==========
    VECTOR = {
        [1] = { main = 1102003100, attachments = {} },
        [2] = { main = 1102003080, attachments = {} }, -- 掠空之翼-Vector(7级)
    },

    -- ========== THOMPSON ==========
    THOMPSON = {
        [1] = { main = 1102004018, attachments = {} }, -- 糖果加农-汤姆逊(5级)
        [2] = { main = 1102004034, attachments = {} }, -- 蒸汽发条-汤姆逊(5级)
    },

    -- ========== BIZON ==========
    BIZON = {
        [1] = { main = 1102005064, attachments = {} },
        [2] = { main = 1102005072, attachments = {} }, -- 炽牙血影-野牛冲锋枪(5级)
        [3] = { main = 1102005078, attachments = {} }, -- PUBGM X 坂本日常 PP19(Lv.5)
    },

    -- ========== MP5K ==========
    MP5K = {
        [1] = { main = 1102007019, attachments = {} }, -- PUBGM X QWER - mp5k(5级)
    },

    -- ========== JS9 ==========
    JS9 = {
        [1] = { main = 1102008001, attachments = {} },
    },

    -- ========== P90 ==========
    P90 = {
        [1] = { main = 1102105028, attachments = {} }, -- 御风神驹-P90(7级)
        [2] = { main = 1102105018, attachments = {} }, -- 金尊神鹰-P90(5级)
        [3] = { main = 1102105012, attachments = {} }, -- 赛博猫妖-P90(7级)
    },

    -- ========== K98 ==========
    K98 = {
        [1] = { main = 1103001202, attachments = {} },
        [2] = { main = 1103001179, attachments = {} }, -- 紫戮电极-Kar98K(7级)
        [3] = { main = 1103001191, attachments = {} }, -- 瑰红花火-Kar98K(7级)
    },

    -- ========== M24 ==========
    M24 = {
        [1] = { main = 1103002156, attachments = {} },
        [2] = { main = 1103002087, attachments = {} }, -- 极尊音律-M24(7级)
        [3] = { main = 1103002059, attachments = {} }, -- 生命循环-M24(7级)
    },

    -- ========== AWM ==========
    AWM = {
        [1] = { main = 1103003099, attachments = {} }, -- 混沌天灾-AWM(7级)
        [2] = { main = 1103003087, attachments = {} }, -- 玲珑白蛇-AWM(7级)
        [3] = { main = 1103003079, attachments = {} }, -- 赤潮龙息-AWM(7级)
        [4] = { main = 1103003062, attachments = {} }, -- 致命炎凤-AWM(7级)
        [5] = { main = 1103003042, attachments = {} }, -- GODZILLA-AWM(7级)
    },

    -- ========== M1Garand ==========
    M1Garand = {
        [1] = { main = 1103103007, attachments = {} }, -- 破军战意-M1加兰德(7级)
    },

    -- ========== Win94 ==========
    Win94 = {
        [1] = { main = 1103008022, attachments = {} },
    },

    -- ========== Mosin ==========
    Mosin = {
        [1] = { main = 1103011003, attachments = {} },
    },

    -- ========== AMR ==========
    AMR = {
        [1] = { main = 1103012039, attachments = {} },
        [2] = { main = 1103012010, attachments = {} }, -- 嗜血龙魇-AMR(8级)
        [3] = { main = 1103012019, attachments = {} }, -- 烈焰圣枪-AMR(7级)
        [4] = { main = 1103012031, attachments = {} }, -- 灵泉剑影-AMR(7级)
    },

    -- ========== DSR ==========
    DSR = {
        [1] = { main = 1103102007, attachments = {} },
    },

    -- ========== SKS ==========
    SKS = {
        [1] = { main = 1103004037, attachments = {} },
    },

    -- ========== VSS ==========
    VSS = {
        [1] = { main = 1103005024, attachments = {} },
    },

    -- ========== Mini14 ==========
    Mini14 = {
        [1] = { main = 1103006030, attachments = {} },
    },

    -- ========== MK14 ==========
    MK14 = {
        [1] = { main = 1103007028, attachments = {} },
        [2] = { main = 1103007038, attachments = {} }, -- 憨憨萌龙-MK14（5级）
        [3] = { main = 1103007043, attachments = {} }, -- 缎带礼盒-MK14(5级)
    },

    -- ========== SLR ==========
    SLR = {
        [1] = { main = 1103009051, attachments = {} },
    },

    -- ========== QBU ==========
    QBU = {
        [1] = { main = 1103010014, attachments = {} },
    },

    -- ========== Mk12 ==========
    Mk12 = {
        [1] = { main = 1103100007, attachments = {} },
    },

    -- ========== S686 ==========
    S686 = {
        [1] = { main = 1104001035, attachments = {} },
    },

    -- ========== S1897 ==========
    S1897 = {
        [1] = { main = 1104002049, attachments = {} },
    },

    -- ========== S12K ==========
    S12K = {
        [1] = { main = 1104003037, attachments = {} }, -- 核子步枪-S12K(5级)
        [2] = { main = 1104003046, attachments = {} }, -- 心动时刻-S12K(5级)
        [3] = { main = 1104003041, attachments = {} },
    },

    -- ========== DBS ==========
    DBS = {
        [1] = { main = 1104004041, attachments = {} },
        [2] = { main = 1104004035, attachments = {} }, -- 异兽战甲-DBS(5级)
        [3] = { main = 1104004051, attachments = {} }, -- 高仓健变身-DBS(5级)
    },

    -- ========== M1014 ==========
    M1014 = {
        [1] = { main = 1104101002, attachments = {} },
    },

    -- ========== NS2000 ==========
    NS2000 = {
        [1] = { main = 1104102004, attachments = {} },
    },

    -- ========== DP28 ==========
    DP28 = {
        [1] = { main = 1105002091, attachments = {} },
        [2] = { main = 1105002106, attachments = {} }, -- 绯红玛丽-DP28(7级)
    },

    -- ========== M249 ==========
    M249 = {
        [1] = { main = 1105001069, attachments = {} },
        [2] = { main = 1105001034, attachments = {} }, -- 派对礼炮-M249(7级)
        [3] = { main = 1105001048, attachments = {} }, -- 极辉女帝-M249(7级)
    },

    -- ========== MG3 ==========
    MG3 = {
        [1] = { main = 1105010019, attachments = {} },
        [2] = { main = 1105010008, attachments = {} }, -- 苍穹之龙-MG3(5级)
        [3] = { main = 1105010026, attachments = {} }, -- 亚白米娜-MG3(5级)
        [4] = { main = 1105010028, attachments = {} }, -- 瑰丽天穹-MG3
    },

    -- ========== 近战 ==========
    PAN = {
        [1] = { main = 1108004027, attachments = {} }, -- 冰雪晶核
        [2] = { main = 1108004416, attachments = {} }, -- 焰舞折扇平底锅(3级)
        [3] = { main = 1108004380, attachments = {} }, -- 红莲哥斯拉平底锅
        [4] = { main = 1081201, attachments = {} }, -- 惩戒者·雷鸣
        [5] = { main = 1108004283, attachments = {} }, -- 至臻壁垒平底锅(6级)
        [6] = { main = 1108004230, attachments = {} }, -- 莎莉-Pan
    },
    DAGGER = {
        [1] = { main = 1108001103, attachments = {} }, -- 锁链手铐-大砍刀(3级)
        [2] = { main = 1108005052, attachments = {} }, -- 清夜蝶吻匕首
        [3] = { main = 1081201, attachments = {} }, -- 惩戒者·雷鸣
        [4] = { main = 1108001069, attachments = {} }, -- Ki Sword
    },
    Machete = {
        [1] = { main = 1108001103, attachments = {} }, -- 锁链手铐-大砍刀(3级)
        [2] = { main = 1108001081, attachments = {} }, -- 红莲战斧(3级)
        [3] = { main = 1081201, attachments = {} }, -- 惩戒者·雷鸣
        [4] = { main = 1108001099, attachments = {} }, -- Juan Soto 棒球棍
        [5] = { main = 1108001069, attachments = {} }, -- Ki Sword
    },
}







-- ==================== 读取配置文件（自由模式） ====================
local function ReadConfigFile()
    local configPath = nil

    -- ★ 优先：按当前包名定位
    local curPath = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath()
    if curPath then
        local f = io.open(curPath, "r")
        if f then f:close(); configPath = curPath end
    end

    -- ★ 回退：按顺序取第一个存在的
    if not configPath then
        for _, path in ipairs(possiblePaths) do
            local file = io.open(path, "r")
            if file then
                file:close()
                configPath = path
                break
            end
        end
    end
    
    if not configPath then return end

    local file = io.open(configPath, "r")
    local content = file:read("*all")
    file:close()

    for line in content:gmatch("[^\r\n]+") do
        if not line:match("^%s*#") then
            local key, value = line:match("(%w+_?%w*)%s*=%s*(%d+)")
            if key and value then
                local index = tonumber(value)
                
-- ==================== 广角配置 ====================
if key == "FOV_ENABLE" then
    _G.ConfigFOVEnable = (index == 1)
    lastConfig[key] = index
    if _G.GameCameraView then pcall(_G.GameCameraView) end
end
if key == "FOV_VALUE" then
    local fovValue = index
    if fovValue < 90 then fovValue = 90 end
    if fovValue > 120 then fovValue = 120 end
    _G.ConfigFOV = fovValue
    lastConfig[key] = index
    if _G.GameCameraView then pcall(_G.GameCameraView) end
end

                -- ==================== 水印开关 ====================
                if key == "WATERMARK" then
                    _G.WatermarkEnabled = (index == 1)
                    lastConfig[key] = index
                end

                -- ==================== 武器检视动画配置 ====================
                if key == "WEAPON_ANIM" then
                    local enabled = (index == 1)
                    if _G.WeaponAnimationModule then
                        _G.WeaponAnimationModule._enabled = enabled
                        _G.WeaponAnimationModule.AUTO_START = enabled
                        if enabled then
                            pcall(function() _G.WeaponAnimationModule.Start() end)
                        else
                            pcall(function() _G.WeaponAnimationModule.Stop() end)
                        end
                    end
                    lastConfig[key] = index
                end

-- ==================== 宠物配置 ====================
if key == "PETSKIN" then
    -- ★ 新格式：存真实宠物ID（>= 50000）
    -- ★ 旧格式：存索引（1~46），做一次兼容反查
    if index > 0 and index < 1000 then
        local petMap = _G.PetSkinMap or {}
        if petMap[index] then
            _G.PetSkinMapIndex = index
            _G.PetSkin = petMap[index]
        end
    else
        _G.PetSkin = index
        _G.PetSkinMapIndex = 1
        for i, id in ipairs(_G.PetSkinMap or {}) do
            if id == index then
                _G.PetSkinMapIndex = i
                break
            end
        end
    end
    lastConfig[key] = index
    if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
end

-- ==================== 拖尾配置 ====================
if key == "TRAIL_ENABLE" then
    if _G.GoldenLeavesTrail then
        _G.GoldenLeavesTrail.Enabled = (index == 1)
        if _G.GoldenLeavesTrail.Enabled then
            pcall(_G.GoldenLeavesTrail.Apply)
        else
            pcall(_G.GoldenLeavesTrail.Stop)
        end
    end
    lastConfig[key] = index
end
if key == "TRAIL_TYPE" then
    local trailId = tonumber(value)
    if trailId == 4531001 or trailId == 4531002 or trailId == 4541001 then
        if _G.GoldenLeavesTrail then
            _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
            if _G.GoldenLeavesTrail.Enabled then
                pcall(_G.GoldenLeavesTrail.Apply)
            end
        end
    end
    lastConfig[key] = index
end

                -- ==================== 天气配置 ====================
                if key == "WEATHER" then
                    _G.WeatherMode = index
                    lastConfig[key] = index
                    if _G.UpdateWeatherMode then
                        _G.UpdateWeatherMode(index)
                    end
                end

                -- ==================== 死亡盒子皮肤开关 ====================
if key == "DEADBOX_SKIN" then
    _G.EnableDeadBoxSkin = (index == 1)
    lastConfig[key] = index
end

-- ==================== 武器极速刷新：配置读到 1 时重建定时器 ====================
if key == "WEAPON_FAST_REFRESH" and lastConfig[key] ~= index then
    lastConfig[key] = index
    local interval = (index == 1) and 1.0 or 1.5
    local ok_tx, tx = pcall(require, "common.time_ticker")
    if ok_tx and tx then
        if _G.weaponAvatarTimerIndex and tx.IsRunning(_G.weaponAvatarTimerIndex) then
            pcall(function() tx.RemoveTimer(_G.weaponAvatarTimerIndex) end)
        end
        _G.weaponAvatarTimerIndex = tx.AddTimerLoop(0, function()
            pcall(_G.GameAvatarHandlerweapons)
        end, -1, interval)
        print("[DazhiMH] WEAPON_FAST_REFRESH=" .. tostring(index) .. " 定时器已重建, interval=" .. tostring(interval))
    end
end

-- ==================== 武器主皮肤（支持预设索引 + CUSTOM_* 自定义ID） ====================
                local isCustom = string.sub(key, 1, 7) == "CUSTOM_"
                local weaponKey = isCustom and string.sub(key, 8) or key
                local weaponID = _G.WeaponNameToID[weaponKey]
                
                if weaponID and lastConfig[key] ~= index then
    _G.WeaponSkinID = _G.WeaponSkinID or {}
    local wantSkin = nil
    if isCustom then
        wantSkin = index
    else
        local skinPack = _G.WeaponSkinPack[key] and _G.WeaponSkinPack[key][index]
        if skinPack and skinPack.main then
            wantSkin = skinPack.main
        end
    end
    if wantSkin and wantSkin > 0 then
        -- ★★★ 修复：写入前校验归属，防配置污染 ★★★
        if _G.isSkinForWeapon and _G.isSkinForWeapon(wantSkin, weaponID) then
            _G.WeaponSkinID[weaponID] = wantSkin
        else
            print(string.format("[ReadConfigFile] ⚠ 拒绝写入: %s 的皮肤=%d 不属于该武器，已忽略",
                tostring(weaponKey), wantSkin))
            _G.WeaponSkinID[weaponID] = nil
        end
    end
    lastConfig[key] = index
                end
            end
        end
    end
    
    -- ==================== 载具皮肤配置 ====================
    local vehicleConfigs = {
        DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
        MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917, RONY = 1916,
        HORSE = 1987, MINIBUS = 1904, BOAT = 19110,  -- ← 对
        ROADSTER = 19116, MIRADO = 1914, MIRADOC = 1915
    }
    
    for line in content:gmatch("[^\r\n]+") do
        if not line:match("^%s*#") then
            local key, value = line:match("(%w+)=(%d+)")
            if key and value then
                local numValue = tonumber(value)
                
-- 载具皮肤
if vehicleConfigs[key] and lastConfig[key] ~= numValue then
    _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
    _G.VehicleSkinIndex[vehicleConfigs[key]] = numValue
    lastConfig[key] = numValue
end
                
                -- 角色装备皮肤
                local roleSkins = {
                    HEADSHAPE = "_G.HeadShapeSkin",SHIRT = "_G.SuitSkin", HAIR = "_G.HairSkin", HAT = "_G.HatSkin",
                    FACE = "_G.FaceSkin", MASK = "_G.MaskSkin", GLOVES = "_G.GlovesSkin",
                    PANT = "_G.PantSkin", SHOE = "_G.ShoeSkin", PARACHUTE = "_G.ParachuteSkin",
                    GLIDER = "_G.GliderSkin", BACKPACK1 = "_G.Backpack1Skin", BACKPACK2 = "_G.Backpack2Skin",
                    BACKPACK3 = "_G.Backpack3Skin", BACKPACK4 = "_G.Backpack4Skin", BACKPACK5 = "_G.Backpack5Skin",
                    BACKPACK6 = "_G.Backpack6Skin", HELMET1 = "_G.Helmet1Skin", HELMET2 = "_G.Helmet2Skin",
                    HELMET3 = "_G.Helmet3Skin", HELMET4 = "_G.Helmet4Skin", HELMET5 = "_G.Helmet5Skin",
                    HELMET6 = "_G.Helmet6Skin",
                    ARMOR1 = "_G.Armor1Skin", ARMOR2 = "_G.Armor2Skin", ARMOR3 = "_G.Armor3Skin",
                    ARMOR4 = "_G.Armor4Skin", ARMOR5 = "_G.Armor5Skin", ARMOR6 = "_G.Armor6Skin"
                }
                if roleSkins[key] and lastConfig[key] ~= numValue then
    local varName = roleSkins[key]:gsub("^_G%.", "")
    -- ★ 强制拦截：滑翔翼和降落伞读到 0 时，恢复默认保底值
    if key == "GLIDER" and numValue <= 0 then
        numValue = 4151133
    elseif key == "PARACHUTE" and numValue <= 0 then
        numValue = 1401469
    end
    _G[varName] = numValue
    lastConfig[key] = numValue
end
            end
        end
    end
end






do
    local ModuleManager = require('client.module_framework.ModuleManager')
    local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
    local download_util = require('client.slua.logic.download.puffer.download_util')
    local PufferConst = require('client.slua.logic.download.puffer_const')
    local PufferManager = require('client.slua.logic.download.puffer.puffer_manager')

    _G.g_parts = {}
    _G.g_parts_subtype = {}

    -- 资源下载检查
    _G.isResourceDownloaded = function(itemId)
        if not itemId or itemId <= 0 then return true end
        local cached = _G.skinDownloadCache[itemId]
        if cached ~= nil then return cached end
        local downloaded = false
        local ok = pcall(function()
            downloaded = download_util.IsDownloaded(itemId)
        end)
        if not ok then
            local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, { itemId })
            downloaded = state == PufferConst.ENUM_DownloadState.Done
        end
        _G.skinDownloadCache[itemId] = downloaded
        return downloaded
    end

    -- 配件ID映射表
    _G.muzzles = {
        id_flash_hider  = { 201010,2010101,2010102,2010103,2010104,2010105, 201005,2010051,2010052,2010053,2010054,201005, 201004,2010041,2010042,2010043,2010044,2010045 },
        id_compensator  = { 201009,2010091,2010092,2010093,2010094,2010095, 201003,2010031,2010032,2010033,2010034,2010035, 201002,2010021,2010022,2010023,2010024,2010025 },
        id_suppressor   = { 201011,2010111,2010112,2010113,2010114,2010115, 201006,2010061,2010062,2010063,2010064,2010065, 201007,2010071,2010072,2010073,2010074,2010075 },
        id_duckbill     = { 201012 },
        id_barrel_ext   = { 201051, 201050, 201055 },
        id_muzzle_brake = { 201053, 201052, 201054 },
    }
    _G.foregrips = {
        id_Angledforegrip = { 202001,2020011,2020012,2020013,2020014,2020015 },
        id_thumb_grip = { 202006,2020061,2020062,2020063,2020064,2020065 },
        id_vertical_grip = { 202002,2020021,2020022,2020023,2020024,2020025 },
        id_light_grip = { 202004,2020041,2020042,2020043,2020044,2020045 },
        id_half_grip = { 202005,2020051,2020052,2020053,2020054,2020055 },
        id_ergonomic_grip = { 202051,2020511,2020512,2020513,2020514,2020515 },
        id_laser_sight = { 202007,2020071,2020072,2020073,2020074,2020075 },
    }
    _G.magazines = {
        id_expanded_mag = { 204011,2040111,2040112,2040113,2040114,2040115, 204007,2040071,2040072,2040073,2040074,2040075, 204004,2040041,2040042,2040043,2040044,2040045, 204015,2040151,2040152,2040153,2040154,2040155 },
        id_quick_mag = { 204012,2040121,2040122,2040123,2040124,2040125, 204008,2040081,2040082,2040083,2040084,2040085, 204005,2040051,2040052,2040053,2040054,2040055 },
        id_expanded_quick_mag = { 204013,2040131,2040132,2040133,2040134,2040135, 204009,2040091,2040092,2040093,2040094,2040095, 204006,2040061,2040062,2040063,2040064,2040065 },
    }
    _G.scopes = {
        id_reddot = 203001, id_holo = 203002, id_2x = 203003, id_4x = 203004,
        id_8x = 203005, id_3x = 203014, id_6x = 203015, id_canted = 203018,
        id_reddot_b = 203051, id_holo_b = 203052, id_2x_b = 203053,
        id_4x_b = 203054, id_8x_b = 203055, id_3x_b = 203056, id_6x_b = 203057,
    }
    _G.stock = {
        id_microStock = 205001, id_tactical = 205002, id_bulletloop = 204014,
        id_CheekPad = 205003, id_heavy = 205010,
    }

    _G.familyKey = {
        id_flash_hider = 'FH', id_compensator = 'CP', id_suppressor = 'SP',
        id_duckbill = 'DK', id_barrel_ext = 'BE', id_muzzle_brake = 'MB',
        id_Angledforegrip = 'AG', id_thumb_grip = 'TG', id_vertical_grip = 'VG',
        id_light_grip = 'LG', id_half_grip = 'HG', id_ergonomic_grip = 'EG', id_laser_sight = 'LS',
        id_expanded_mag = 'EM', id_quick_mag = 'QM', id_expanded_quick_mag = 'EQ',
        id_reddot = 'RD', id_holo = 'HO', id_2x = 'S2', id_3x = 'S3', id_4x = 'S4',
        id_6x = 'S6', id_8x = 'S8', id_canted = 'CS',
        id_reddot_b = 'RD', id_holo_b = 'HO', id_2x_b = 'S2', id_3x_b = 'S3',
        id_4x_b = 'S4', id_6x_b = 'S6', id_8x_b = 'S8',
        id_microStock = 'ST', id_tactical = 'TS', id_bulletloop = 'BL',
        id_CheekPad = 'CH', id_heavy = 'HS',
    }

    _G.idToFamily = {}
    _G.knownIDs = {}
    local function reg(id, fam)
        if id and id > 0 then _G.idToFamily[id] = fam _G.knownIDs[id] = true end
    end
    for f, l in pairs(_G.muzzles) do for _, id in ipairs(l) do reg(id, f) end end
    for f, l in pairs(_G.foregrips) do for _, id in ipairs(l) do reg(id, f) end end
    for f, l in pairs(_G.magazines) do for _, id in ipairs(l) do reg(id, f) end end
    for f, id in pairs(_G.scopes) do reg(id, f) end
    for f, id in pairs(_G.stock) do reg(id, f) end

    local SUBTYPE_MUZZLE, SUBTYPE_SCOPE, SUBTYPE_STOCK, SUBTYPE_MAG, SUBTYPE_GRIP = 201, 202, 203, 204, 205

    local function splitStr(str, sep)
        local t = {}
        if not str or str == '' then return t end
        for part in string.gmatch(str, '([^' .. sep .. ']+)') do table.insert(t, part) end
        return t
    end

    local function get_group_id(itemId)
        if not ItemUpgradeSystem or not itemId then return nil end
        local c = ItemUpgradeSystem:GetUpgradeCfg(itemId)
        return c and c.GroupID or nil
    end

    local function getFamily(id)
        return id and _G.idToFamily[id]
    end

    local function getPartOriginID(partId)
        if not partId or partId == 0 then return 0 end
        local ok, cfg = pcall(function() return CDataTable.GetTableData('WeaponAttachAttrBPTable', partId) end)
        if ok and cfg and cfg.ParentID and cfg.ParentID > 0 then return cfg.ParentID end
        return 0
    end

    local function getBPID(resId)
        local bp = resId
        pcall(function()
            local UAvatarUtils = import('AvatarUtils')
            if UAvatarUtils and UAvatarUtils.GetBPIDByResID then
                local v = UAvatarUtils.GetBPIDByResID(resId)
                if v and v > 0 then bp = v end
            end
        end)
        pcall(function()
            local UBackpackUtils = import('BackpackUtils')
            if UBackpackUtils and UBackpackUtils.GetBPIDByResID then
                local v = UBackpackUtils.GetBPIDByResID(resId)
                if v and v > 0 then bp = v end
            end
        end)
        return bp
    end

    -- 保存配件映射
    local function savePart(skinId, baseId, skinPartId)
        if not skinId or not baseId or not skinPartId or baseId <= 0 or skinPartId <= 0 then return end
        _G.g_parts[skinId][baseId] = skinPartId
        local fam = getFamily(baseId)
        if not fam then return end
        local key = _G.familyKey[fam]
        if key then _G.g_parts[skinId][key] = skinPartId end
        if _G.muzzles[fam] then
            for _, id in ipairs(_G.muzzles[fam]) do 
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.magazines[fam] then
            for _, id in ipairs(_G.magazines[fam]) do 
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.foregrips[fam] then
            for _, id in ipairs(_G.foregrips[fam]) do
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.scopes[fam] then
            for fid, f in pairs(_G.scopes) do 
                if f == fam then 
                    _G.g_parts[skinId][fid] = skinPartId 
                end 
            end
        elseif _G.stock[fam] then
            _G.g_parts[skinId][_G.stock[fam]] = skinPartId
        end
    end

    local function saveBySubType(skinId, subType, skinPartId)
        if not skinId or not subType or not skinPartId or skinPartId <= 0 then return end
        if not _G.g_parts_subtype[skinId] then _G.g_parts_subtype[skinId] = {} end
        _G.g_parts_subtype[skinId][subType] = skinPartId
    end

    -- 初始化配件映射（从游戏数据表读取）
    _G.InitParts = function(groupId, itemId)
        if not itemId then return _G.g_parts end
        if not _G.g_parts[itemId] then _G.g_parts[itemId] = {} end
        if not _G.g_parts_subtype[itemId] then _G.g_parts_subtype[itemId] = {} end

        pcall(function()
            local bpId = getBPID(itemId)
            local tryIds = { bpId, itemId }
            local icfg = CDataTable.GetTableData('Item', itemId)
            if icfg and icfg.BPID and icfg.BPID > 0 then table.insert(tryIds, icfg.BPID) end
            for _, tid in ipairs(tryIds) do
                local cfg = CDataTable.GetTableData('WeaponAttrBPTable', tid)
                if cfg and cfg.AttachmentSkinIDList and cfg.AttachmentSkinIDList ~= '' then
                    for _, pair in ipairs(splitStr(cfg.AttachmentSkinIDList, '|')) do
                        local nums = splitStr(pair, '-')
                        local b, s = tonumber(nums[1]), tonumber(nums[2])
                        if b and s then savePart(itemId, b, s) end
                    end
                end
            end
        end)

        if ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
            groupId = ItemUpgradeSystem:GetNormalGroupID(groupId or get_group_id(itemId))
        else
            groupId = groupId or get_group_id(itemId)
        end

        pcall(function()
            local partsDic = ItemUpgradeSystem:GetPartsDic(groupId)
            if partsDic then
                for subType, partList in pairs(partsDic) do
                    for _, partId in ipairs(partList) do
                        local skinPartId = partId
                        if ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                            local sw = ItemUpgradeSystem:PartIDSwitch(partId, true)
                            if sw and sw ~= partId then skinPartId = sw end
                        end
                        saveBySubType(itemId, subType, skinPartId)
                        local parent = getPartOriginID(skinPartId)
                        if parent == 0 then parent = getPartOriginID(partId) end
                        if parent > 0 then
                            savePart(itemId, parent, skinPartId)
                        elseif _G.knownIDs[partId] then
                            savePart(itemId, partId, skinPartId)
                        end
                    end
                end
            end
        end)

        pcall(function()
            local UAvatarUtils = import('AvatarUtils')
            if UAvatarUtils and UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin then
                local list = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(itemId, {}, false) or {}
                for baseId, skinPartId in pairs(list) do
                    if baseId and skinPartId and skinPartId > 0 then
                        if _G.knownIDs[baseId] then
                            savePart(itemId, baseId, skinPartId)
                        else
                            local parent = getPartOriginID(skinPartId)
                            if parent > 0 then savePart(itemId, parent, skinPartId)
                            else _G.g_parts[itemId][baseId] = skinPartId end
                        end
                    end
                end
            end
        end)

        return _G.g_parts
    end

-- ==================== 自定义配件皮肤（在这里加你的配置） ====================
-- 格式: [武器皮肤ID] = { [配件ID] = 配件皮肤ID, ... }
-- 武器皮肤ID:  WeaponSkinPack 里的 main 值，如 1101006106=九尾之助-AUG
-- 配件ID:      红点=203001 全息=203002 2倍=203003 3倍=203014 4倍=203004 6倍=203015 8倍=203005
--              消音器AR=201011 消音器SMG=201006 消音器SR=201007 补偿器AR=201009 消焰器AR=201010
--              垂直握把=202002 轻型握把=202004 半截握把=202005 拇指握把=202006 激光=202007 直角握把=202001
--              AR扩容=204011 AR快扩=204013 战术枪托=205002 托腮板=205003
-- 配件皮肤ID:  你要换成的那款配件皮肤的物品ID（8位，如 1010061038）
_G.CustomAttachmentSkin = {
    [1101006106] = {              -- 九尾之助-AUG(8级)
        [203001] = 1010060998,    -- 红点瞄准镜 → 换成指定红点皮肤
        [203002] = 1010060997,    -- 全息瞄准镜 → 换成指定红点皮肤
        [203003] = 1010060996,    -- 2倍瞄准镜 → 换成指定红点皮肤
        [203014] = 1010060995,    -- 3倍瞄准镜 → 换成指定红点皮肤
        [203004] = 1010060994,    -- 4倍瞄准镜 → 换成指定红点皮肤
        [203015] = 1010060993,    -- 6倍瞄准镜 → 换成指定红点皮肤
        [201010] = 1010061005,    -- 消焰器
        [201011] = 1010061006,    -- 消音器
        [201009] = 1010061004,    -- 枪口补偿器
        [202001] = 1010061007,    -- 直角前握把
        [202006] = 1010061008,    -- 拇指握把
        [202002] = 1010061009,    -- 垂直握把
        [202007] = 1010061010,    -- 激光瞄准器
        [202004] = 1010060973,    -- 轻型握把
        [202005] = 1010060974,    -- 半截式握把
        [204011] = 1010061000,    -- 快速弹夹
        [204012] = 1010060999,    -- 扩容弹夹
        [204013] = 1010061003,    -- 快速扩容弹夹
    },
    [1101006098] = {              -- 九尾之怒-AUG(8级)
        [203001] = 1010060958,    -- 红点瞄准镜
        [203002] = 1010060957,    -- 全息瞄准镜
        [203003] = 1010060956,    -- 2倍瞄准镜
        [203014] = 1010060955,    -- 3倍瞄准镜
        [203004] = 1010060954,    -- 4倍瞄准镜
        [203015] = 1010060953,    -- 6倍瞄准镜
        [201010] = 1010060965,    -- 消焰器
        [201011] = 1010060966,    -- 消音器
        [201009] = 1010060964,    -- 枪口补偿器
        [202001] = 1010060967,    -- 直角前握把
        [202006] = 1010060968,    -- 拇指握把
        [202002] = 1010060969,    -- 垂直握把
        [202007] = 1010060970,    -- 激光瞄准器
        [202004] = 1010060973,    -- 轻型握把
        [202005] = 1010060974,    -- 半截式握把
        [204011] = 1010060960,    -- 快速弹夹
        [204012] = 1010060959,    -- 扩容弹夹
        [204013] = 1010060963,    -- 快速扩容弹夹
    },
}
-- ==================== 自定义配件皮肤 END ====================

-- ★ 兼容：用户可能只配 CustomAttachmentSkin，九尾相关表可能没定义，空表兜底
_G.NineTailsParts = _G.NineTailsParts or {}

local NINE_BASE_TO_KEY = {
    [203001] = "RD", [203002] = "HO", [203003] = "S2", [203004] = "S4",
    [203014] = "S3", [203015] = "S6", [203018] = "CS",
    [203051] = "RD", [203052] = "HO", [203053] = "S2", [203054] = "S4",
    [203055] = "S8", [203056] = "S3", [203057] = "S6",
    [201002] = "CP", [201003] = "CP", [201009] = "CP",
    [201004] = "FH", [201005] = "FH", [201010] = "FH",
    [201006] = "SP", [201007] = "SP", [201011] = "SP",
    [202001] = "AG", [202002] = "VG", [202004] = "LG",
    [202005] = "HG", [202006] = "TG", [202007] = "LS",
    [204004] = "EM", [204007] = "EM", [204011] = "EM", [204015] = "EM",
    [204005] = "QM", [204008] = "QM", [204012] = "QM",
    [204006] = "EQ", [204009] = "EQ", [204013] = "EQ",
}

function _G.GetNineTailsPartSkin(avatarid, current_id)
    -- ★ nil 保护：用户可能删了九尾配置，用空表兜底
    local ntParts = _G.NineTailsParts
    if not ntParts then return nil end
    local group = ntParts[avatarid]
    if not group then return nil end
    _G.NINE_TAILS_SKIN = _G.NINE_TAILS_SKIN or {}
local map = _G.NINE_TAILS_SKIN[group]
    if not map then return nil end
    -- ① 直接按 base 配件ID命中
    local key = NINE_BASE_TO_KEY[current_id]
    if key and map[key] then return map[key] end
    -- ② 走 familyKey 兜底（皮肤配件ID/别名配件都能命中）
    local fam = _G.idToFamily and _G.idToFamily[current_id]
    if fam then
        local k = _G.familyKey and _G.familyKey[fam]
        if k and map[k] then return map[k] end
    end
    return nil
end

    -- 查找配件皮肤
local function findSkin(current_id, avatarid, slot, subType)
    if not _G.isResourceDownloaded(avatarid) then return nil end

    -- ★★★ 自定义配件皮肤最优先（覆盖九尾和游戏默认映射）★★★
    local custMap = _G.CustomAttachmentSkin and _G.CustomAttachmentSkin[avatarid]
    if custMap and current_id then
        -- ① 直接命中 base 配件ID（红点 203001 / 消音 201011 等）
        local c1 = custMap[current_id]
        if c1 and c1 > 0 and _G.isResourceDownloaded(c1) then
            return c1
        end
        -- ② current 是皮肤配件ID → 回溯 base 再命中
        local baseId = getPartOriginID(current_id)
        if baseId > 0 then
            local c2 = custMap[baseId]
            if c2 and c2 > 0 and _G.isResourceDownloaded(c2) then
                return c2
            end
        end
        -- ③ family 兜底：customKey 与 current 属于同一家族
        local famCust = getFamily(current_id)
        if famCust then
            for sid, sv in pairs(custMap) do
                if type(sid) == 'number' and sv and sv > 0
                   and getFamily(sid) == famCust
                   and _G.isResourceDownloaded(sv) then
                    return sv
                end
            end
        end
        -- ④ NINE_BASE_TO_KEY 反查兜底（current 是九尾皮肤配件ID时）
        local curKey = NINE_BASE_TO_KEY[current_id]
        if curKey then
            for baseId, sv in pairs(custMap) do
                if type(baseId) == 'number' then
                    local bk = NINE_BASE_TO_KEY[baseId]
                    if bk == curKey and sv and sv > 0 and _G.isResourceDownloaded(sv) then
                        return sv
                    end
                end
            end
        end
    end

    -- ★ 九尾AUG配件皮肤兜底（自定义没命中时才走；用 pcall 保护，防止 GetNineTailsPartSkin 内部报错）
    if _G.NineTailsParts and next(_G.NineTailsParts) then
        local ok, nineSkin = pcall(_G.GetNineTailsPartSkin, avatarid, current_id)
        if ok and nineSkin and _G.isResourceDownloaded(nineSkin) then
            return nineSkin
        end
    end

    -- ★ 功耗：每个 avatarid 只 init 一次（原逻辑保留）
    if not _G.__perf.partsInited[avatarid] then
        _G.__perf.partsInited[avatarid] = true
        _G.InitParts(get_group_id(avatarid), avatarid)
    end
        local p = _G.g_parts[avatarid]
        if not p then return nil end
        if p[current_id] and p[current_id] > 0 then
            local candidate = p[current_id]
            if _G.isResourceDownloaded(candidate) then return candidate end
        end
        local fam = getFamily(current_id)
        if fam then
            local key = _G.familyKey[fam]
            if key and p[key] and p[key] > 0 and _G.isResourceDownloaded(p[key]) then return p[key] end
            for sid, sv in pairs(p) do
                if type(sid) == 'number' and getFamily(sid) == fam and sv > 0 and _G.isResourceDownloaded(sv) then
                    return sv
                end
            end
        end
        if subType then
            local st = _G.g_parts_subtype[avatarid]
            if st and st[subType] and st[subType] > 0 then
                local candidate = st[subType]
                if _G.isResourceDownloaded(candidate) then return candidate end
            end
        end
        return nil
    end

    -- 解析配件ID
    local function resolve(id, av, slot, subType)
        local init = id
        if not id or id <= 0 then return id, false end
        if not _G.isResourceDownloaded(av) then return id, false end
        local s = findSkin(id, av, slot, subType)
        if s and s > 0 then
            if s ~= id and not _G.isResourceDownloaded(s) then return id, false end
            return s, s ~= init
        end
        return id, false
    end

    -- 导出配件解析函数
    _G.get_muzzleid = function(id, av) return resolve(id, av, 0, SUBTYPE_MUZZLE) end
    _G.get_forgripid = function(id, av) return resolve(id, av, 4, SUBTYPE_GRIP) end
    _G.get_magazinesid = function(id, av) return resolve(id, av, 1, SUBTYPE_MAG) end
    _G.get_scopeid = function(id, av) return resolve(id, av, 3, SUBTYPE_SCOPE) end
    _G.get_stockid = function(id, av) return resolve(id, av, 2, SUBTYPE_STOCK) end

    -- 应用配件皮肤到武器
    _G.apply_attachment = function(CurWeapon, avatarid)
    if not CurWeapon or not avatarid or avatarid <= 0 then return false end
    if not _G.isResourceDownloaded(avatarid) then return false end

    -- ★ 功耗：同一把枪同皮肤 3 秒内只处理一次
    local key = tostring(CurWeapon) .. "|" .. tostring(avatarid)
    local now = os.clock()
    if now - (_G.__perf.attachStamp[key] or 0) < 3 then return false end
    _G.__perf.attachStamp[key] = now

    local array = CurWeapon.synData
        if not array or not slua.isValid(array) then return false end
        local changed = false
        for AttachIdx = 0, 4 do
            local Data = array:Get(AttachIdx)
            if Data and slua.isValid(Data) then
                local itemid = slua.IndexReference(Data, 'defineID').TypeSpecificID
                if itemid and itemid > 0 and itemid < 10000000 then
                    local newId, isrefresh
                    if AttachIdx == 0 then
                        newId, isrefresh = _G.get_muzzleid(itemid, avatarid)
                    elseif AttachIdx == 1 then
                        newId, isrefresh = _G.get_forgripid(itemid, avatarid)
                    elseif AttachIdx == 2 then
                        newId, isrefresh = _G.get_magazinesid(itemid, avatarid)
                    elseif AttachIdx == 3 then
                        newId, isrefresh = _G.get_stockid(itemid, avatarid)
                    elseif AttachIdx == 4 then
                        newId, isrefresh = _G.get_scopeid(itemid, avatarid)
                    end
                    if isrefresh then
                        slua.IndexReference(Data, 'defineID').TypeSpecificID = newId
                        array:Set(AttachIdx, Data)
                        changed = true
                    end
                end
            end
        end
        if changed then
            pcall(function() CurWeapon:DelayHandleAvatarMeshChanged() end)
        end
        return changed
    end

    -- 装备武器皮肤（每次都强制刷新配件）
    _G.equip_weapon_avatar = function(uCharacter)
        if not uCharacter or not slua.isValid(uCharacter) then return end
        local WeaponManager = uCharacter:GetWeaponManager()
        if not WeaponManager or not slua.isValid(WeaponManager) then return end
        local uWeaponList = WeaponManager:GetAllInventoryWeaponList(false)
        if not uWeaponList or not slua.isValid(uWeaponList) then return end
        
        for i = 0, uWeaponList:Num() - 1 do
            local CurWeapon = uWeaponList:Get(i)
            if slua.isValid(CurWeapon) then
                local AttachmentArray = CurWeapon.synData
                if not AttachmentArray or not slua.isValid(AttachmentArray) then goto continue_weapon end
                
                local AttachmentData = AttachmentArray:Get(7)
                if not AttachmentData or not slua.isValid(AttachmentData) then goto continue_weapon end
                
                local current_skin_id = slua.IndexReference(AttachmentData, 'defineID').TypeSpecificID
                if not current_skin_id or current_skin_id <= 0 then goto continue_weapon end
                
                local weapon_id = CurWeapon:GetWeaponID()
                if current_skin_id == weapon_id then goto continue_weapon end
                
                if not _G.isResourceDownloaded(current_skin_id) then goto continue_weapon end
                
                -- 每次都强制刷新配件
                _G.apply_attachment(CurWeapon, current_skin_id)
            end
            ::continue_weapon::
        end
    end
end

-- ==================== 武器皮肤获取函数（只返回皮肤ID） ====================
-- ★★★ 判断皮肤是否真的属于该武器（核心防污染函数）★★★
function _G.isSkinForWeapon(skinId, baseWid)
    if not skinId or not baseWid then return false end
    skinId = tonumber(skinId)
    baseWid = tonumber(baseWid)
    if not skinId or not baseWid then return false end

    -- 原皮：ID相同
    if skinId == baseWid then return true end

    -- 常规：皮肤的base 必须等于 baseWid
    local skinBase = baseWid
    if _G.getBaseWeaponID then
        local ok, b = pcall(_G.getBaseWeaponID, skinId)
        if ok and b then skinBase = tonumber(b) or skinId end
    else
        skinBase = skinId
    end
    if skinBase == baseWid then return true end

    -- ★ 共用近战皮肤放行：1081201「惩戒者·雷鸣」可给任意近战使用
    if skinId == 1081201 then
        if baseWid == 108001 or baseWid == 108004 or baseWid == 108005 then
            return true
        end
    end

    return false
end

function _G.get_skin_id2(weaponID)
    if not weaponID then return nil end
    local baseWeaponID = _G.getBaseWeaponID(weaponID)
    local targetSkinID = baseWeaponID
    
    if _G.WeaponSkinID and _G.WeaponSkinID[baseWeaponID] and _G.WeaponSkinID[baseWeaponID] ~= 0 then
        local skin = _G.WeaponSkinID[baseWeaponID]
        -- ★★★ 修复：皮肤的归属必须匹配，不匹配就当成污染清掉 ★★★
        if _G.isSkinForWeapon(skin, baseWeaponID) then
            targetSkinID = skin
        else
            print(string.format("[get_skin_id2] ⚠ 清除污染: base=%d 存了错误皮肤=%d，已恢复原皮",
                baseWeaponID, skin))
            _G.WeaponSkinID[baseWeaponID] = nil
        end
    end
    
    return targetSkinID
end

--ApplyCachedAttachments 函数
_G.attachmentCache = _G.attachmentCache or {}

-- ==================== 统一刷新函数（武器主皮肤 + 配件 + 无手持刷新） ====================
function _G.GameAvatarHandlerweapons()
    pcall(function()
        local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not PlayerController then return end
        
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if not uCharacter or not slua.isValid(uCharacter) then return end
        
        local isBackRefresh = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("WEAPON_BACK_REFRESH", 0) == 1)
        local processed = {}
        local _wkChanged = false

        -- ★ 刷背包/背上的武器（如果开了开关）
        if isBackRefresh then
            local wm = uCharacter:GetWeaponManager()
            if wm and slua.isValid(wm) then
                local list = wm:GetAllInventoryWeaponList(false)
                if list and slua.isValid(list) then
                    for i = 0, list:Num() - 1 do
                        local w = list:Get(i)
                        if w and slua.isValid(w) then
                            local wid = w:GetWeaponID()
                            if wid and wid > 0 then
                                local targetSkinID = _G.get_skin_id2(wid)
                                local arr = w.synData
                                if arr and slua.isValid(arr) then
                                    local d = arr:Get(7)
                                    if d and slua.isValid(d) then
                                        local currentSkinID = slua.IndexReference(d, "defineID").TypeSpecificID
                                        if currentSkinID ~= targetSkinID then
                                            -- ★ 核心修复：背上的枪只改数据，绝不调用 DelayHandleAvatarMeshChanged，否则必崩溃
                                            slua.IndexReference(d, "defineID").TypeSpecificID = targetSkinID
                                            arr:Set(7, d)
                                            _wkChanged = true
                                        end
                                    end
                                end
                                -- 配件交给统一函数处理
                                if _G.apply_attachment then
                                    _G.apply_attachment(w, targetSkinID)
                                end
                                processed[tostring(w)] = true
                            end
                        end
                    end
                end
            end
        end
        
                -- 处理当前手持武器的自定义皮肤
local currweapon = uCharacter:GetCurrentWeapon()
if currweapon and slua.isValid(currweapon) and not processed[tostring(currweapon)] then
    local wid = currweapon:GetWeaponID()
    if wid and wid > 0 then
        local targetSkinID = _G.get_skin_id2(wid)
        -- ★★★ 双保险：刷皮前再校验一次归属 ★★★
        if targetSkinID and not (_G.isSkinForWeapon and _G.isSkinForWeapon(targetSkinID, _G.getBaseWeaponID(wid))) then
            targetSkinID = _G.getBaseWeaponID(wid)
        end
        local arr = currweapon.synData
        if arr and slua.isValid(arr) then
                    local d = arr:Get(7)
                    if d and slua.isValid(d) then
                        local currentSkinID = slua.IndexReference(d, "defineID").TypeSpecificID
                        if currentSkinID ~= targetSkinID then
                            slua.IndexReference(d, "defineID").TypeSpecificID = targetSkinID
                            arr:Set(7, d)
                            _wkChanged = true
                            -- 只有当前手持的武器才允许刷新模型
                            if currweapon.DelayHandleAvatarMeshChanged then
                                currweapon:DelayHandleAvatarMeshChanged()
                            end
                        end
                    end
                end
            end
        end
        
        -- 统一刷新所有武器配件（包括背包里的）
        -- ★ 优化：只有真的改了皮肤数据才重建配件，避免每帧无意义重建导致卡顿
        if _wkChanged and _G.equip_weapon_avatar then
            _G.equip_weapon_avatar(uCharacter)
        end
    end)
end

-- ==================== 定时器 ====================
local TXtime_ticker = require("common.time_ticker")
if _G.weaponAvatarTimerIndex and TXtime_ticker.IsRunning(_G.weaponAvatarTimerIndex) then
    TXtime_ticker.RemoveTimer(_G.weaponAvatarTimerIndex)
end

-- ★ 支持 WEAPON_FAST_REFRESH 动态调整刷新间隔
local function getWeaponRefreshInterval()
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        local fast = _G.DazhiMH_Config.Get("WEAPON_FAST_REFRESH", 0)
        if fast == 1 then return 1.0 end
    end
    return 1.5
end

_G.weaponAvatarTimerIndex = TXtime_ticker.AddTimerLoop(0, function()
    pcall(_G.GameAvatarHandlerweapons)
end, -1, getWeaponRefreshInterval())




-- ==================== 载具皮肤（整合新载具.lua所有皮肤ID） ====================

_G.VehskinIdMappings = {

    -- ========== 摩托车 ==========
    -- 单人摩托车
    [1901] = {
        1901001, 1901091, 1901073, 1901074, 1901075, 1901076, 1901070, 1901098, 1901102,
        1901107, 1901108, 1901109, 1901110
    },
    -- 三人摩托车
    [1902] = {
        1902001, 1902030, 1902026, 1902067
    },
    -- 踏板摩托
    [1917] = {
        1917001, 1917006
    },

    -- ========== 轿车 (Dacia) ==========
    [1903] = {
        -- 来自新载具.lua SKIN_IDS
        1903218, -- Porsche Panamera Turbo S(宝石蓝)
        1903219, -- Porsche Panamera Turbo S(蝰蛇绿)
        1903220, -- Apollo Intensa Emozione（熔岩流火）
        1903221, -- Apollo Intensa Emozione（魅影紫罗兰）
        1903222, -- Apollo Intensa Emozione（争锋对决）
        1903223, -- Apollo Intensa Emozione（风暴之眼）
        1903014, -- 
        1903212, -- 蜂暴烈芒轿车
        1903213, -- 疾影黄蜂轿车
        1903074, -- Koenigsegg Gemera（银灰）
        1903075, -- Koenigsegg Gemera（虹影）
        1903076, -- Koenigsegg Gemera（启明）        
        1903192, -- 迅灵紫夜
        1903193, -- 迅灵光穹
        1903079, -- Lamborghini Estoque 金辉
    },

    -- ========== 双座跑车 Coupe RB ==========
    [1961] = {
        -- 来自新载具.lua SKIN_IDS
        1961070, -- Ferrari LaFerrari(疾速焰纹)
        1961071, -- Ferrari LaFerrari(竞速红)
        1961072, -- Ferrari LaFerrari(黑檀琉璃)
        1961073, -- Ferrari LaFerrari(绯红霓章)
        1961047, -- Bugatti La Voiture Noire 冻港
        1961043, -- Bugatti Veyron 16.4
        1961045, -- Bugatti La Voiture Noire 星云
        1961049, -- Aston Martin Valkyrie 极光绿影
        1961048, -- Aston Martin Valkyrie 宝钻辉光
        1961032, -- Koenigsegg One:1 凤凰
        1961031, -- Koenigsegg One:1 瑰玉
        1961030, -- Koenigsegg One:1 赛博星云
        1961029, -- Koenigsegg One:1 鎏金        
        1961025, -- Lamborghini Centenario 夜都
        1961021, -- Lamborghini Centenario 银河
        1961020, -- Lamborghini Aventador SVJ 绿野
        1961024, -- Lamborghini Aventador SVJ 魅蓝
        1961034, -- 跃迁曙光
        1961033, -- 跃迁翠岚
        1961065, -- Apollo EVO（璀璨鎏金）
        1961062, -- Porsche 918 Spyder(水波纹)
        1961066, -- Apollo EVO（日落终章）
        1961152, -- Bugatti Bolide 曼珠沙华
        1961067, -- Apollo EVO（苍雪皑刃）
        1961063, -- Porsche 918 Spyder(极光银)
        1961064, -- Porsche 918 Spyder(粉红猪)
        1961151, -- Bugatti Bolide 镜面刀锋
        1961153, -- Bugatti Bolide 冰湖幻影
        1961147, -- 迈凯伦P1星空
        1961148, -- 迈凯伦P1梦幻粉
        1961149, -- 迈凯伦P1火山黄
        1961144, -- 兰博基尼Invencible嫣红瑰影
        1961145, -- 兰博基尼Invencible浪迹星云
        1961054, -- Pagani Imola 苍灰山脊
        1961055, -- Pagani Imola 纯澈暗烬
        1961056, -- Pagani Imola 星云幻彩
        1961057, -- Pagani Imola 极地寒甲
    },

    -- ========== Roadster双座敞篷跑车 ==========
    [19116] = {
        19116002, -- Ferrari SF90 XX Spider(竞速红)
        19116003, -- Ferrari SF90 XX Spider(霜月凝辉)
        19116004, -- Ferrari SF90 XX Spider(赛车极客)
    },

    -- ========== Mirado敞篷跑车 ==========
    [1915] = {
        1915021, -- Porsche 911 Carrera 4 GTS Cabriolet(星光紫)
        1915022, -- Porsche 911 Carrera 4 GTS Cabriolet(星光宝石红)
        1915017, -- 天罚威震敞篷轿车
        1915018, -- 深渊仲裁敞篷轿车
        1915005, -- Aston Martin DBS Volante 星穹银河
        1915006, -- Aston Martin DBS Volante 幻境粉钻
        1915007, -- Aston Martin DBS Volante 极夜古铜
        1915008, -- Bentley Continental GT Convertible Mulliner（玲珑梦境）
        1915009, -- Bentley Continental GT Convertible Mulliner（紫衣贵族）
    },

    -- ========== UAZ吉普车 ==========
    [1908] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },
    [1909] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },
    [1910] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },

    -- ========== 罗尼皮卡 ==========
    [1916] = { 1916001, 1916004, 1916005, 1916006 },

    -- ========== Buggy越野车 ==========
    [1907] = { 1907001, 1907054, 1907058, 1907059, 1907011, 1907012, 1907013, 1907014, 1907015 },

    -- ========== 大脚车 ==========
    [1953] = { 1953001, 1953004, 1953008 },

    -- ========== UTV全地形车 ==========
    [1966] = { 1966017, 1966016 },

    -- ========== PG117船 ==========
    [19110] = { 1911001, 1911013, 1911003, 1911004, 1911005, 1911006, 1911007, 1911008, 1911009, 1911010, 1911011, 1911012 },

    -- ========== 巴士 ==========
    [1904] = { 1904001, 1904002, 1904003, 1904004, 1904005, 1904007, 1904008, 1904009, 1904010, 1904011, 1904012 },

    -- ========== 马 ==========
    [1987] = { 1987002, 1987004 },

}

-- 载具配置键值映射（用于配置文件读取）
_G.VEHICLE_CONFIG_KEYS = {
    DACIA = 1903,
    COUPERB = 1961,
    BUGGY = 1907,
    UAZ = 1908,
    MOTO = 1901,
    SIDECARMOTO = 1902,
    BLOOMSC = 1917,
    RONY = 1916,
    RZR = 1966,
    BIGFOOT = 1953,
    HORSE = 1987,
    MINIBUS = 1904,
    BOAT = 1911,
    ROADSTER = 19116,
    MIRADO = 1914,
    MIRADOC = 1915,
}

-- ========== 载具皮肤获取函数 ==========
function _G.get_vehicle_skin_id(vehicleID)
    if not vehicleID then return nil end
    local vehicleSkins = _G.VehskinIdMappings[vehicleID]
    if not vehicleSkins then return vehicleID end
    local index = (_G.VehicleSkinIndex and _G.VehicleSkinIndex[vehicleID]) or 1
    if index < 1 or index > #vehicleSkins then index = 1 end
    local skinID = vehicleSkins[index]
    if not skinID then return vehicleID end
    if not _G.skinIdCache3[skinID] then
        pcall(_G.download_item, skinID)
        _G.skinIdCache3[skinID] = true
    end
    return skinID
end

-- ========== 载具皮肤处理函数 ==========
function _G.GameVehicleAvatarHandler()
    pcall(function()
        local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not PlayerController then return end
        
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if not uCharacter or not slua.isValid(uCharacter) then return end
        
        local CurrentVehicle = uCharacter.CurrentVehicle
        if CurrentVehicle and slua.isValid(CurrentVehicle) then
            local VehicleAvatar = CurrentVehicle.VehicleAvatar
            if VehicleAvatar then
                local DefaultAvatarID = VehicleAvatar:GetDefaultAvatarID()
                local CurrentAvatarID = CurrentVehicle:GetAvatarId()
                local defStr = tostring(DefaultAvatarID)
                for vehicleId, skinIdTable in pairs(_G.VehskinIdMappings) do
                    local vidStr = tostring(vehicleId)
                    if DefaultAvatarID == vehicleId or defStr:sub(1, #vidStr) == vidStr then
                        local skinId = _G.get_vehicle_skin_id(vehicleId)
                        if skinId and CurrentAvatarID ~= skinId then
                            VehicleAvatar:ChangeItemAvatar(skinId, true)
                            _G.CurrentEquipVehicleID = skinId
                        end
                        break
                    end
                end
            end
        end
    end)
end


-- ==================== 大厅展示载具皮肤刷新 ====================
do
    -- 缓存：同一 Actor 已应用相同皮肤 → 跳过
    _G.__LobbyVehSkinCache = _G.__LobbyVehSkinCache or {}

    -- ========== 应用单个载具 Actor ==========
    function _G._ApplyVehicleSkinToActor(vehicle)
        if not vehicle or not slua.isValid(vehicle) then return false end
        local VA = vehicle.VehicleAvatar
        if not VA or not slua.isValid(VA) then return false end

        local defId = nil
        pcall(function() defId = VA:GetDefaultAvatarID() end)
        if not defId then return false end

        local defStr = tostring(defId)
        for vehicleId in pairs(_G.VehskinIdMappings or {}) do
            local vidStr = tostring(vehicleId)
            if defId == vehicleId or defStr:sub(1, #vidStr) == vidStr then
                local skinId = _G.get_vehicle_skin_id(vehicleId)
if not skinId then return false end

-- ★ 先检查当前 actor 已是目标 skin → 不刷（防闪烁）
local curId = 0
pcall(function() curId = vehicle:GetAvatarId() or 0 end)
if curId == skinId then
    _G.__LobbyVehSkinCache[vehicle] = skinId
    return false
end

-- 缓存命中 → 不刷
local cache = _G.__LobbyVehSkinCache
if cache[vehicle] == skinId then return false end

pcall(function() VA:ChangeItemAvatar(skinId, true) end)
cache[vehicle] = skinId
_G.CurrentEquipVehicleID = skinId
return true
            end
        end
        return false
    end

    -- ★★★ 大厅主题黑名单：选这两个主题时，绝不刷大厅载具 ★★★
local _VEH_REFRESH_THEME_BLACKLIST = {
    [202408061] = true,
    [202408087] = true,
}

-- 当前大厅主题是否在黑名单里（只用游戏内部字段，不读文件，避免卡顿）
local function _IsThemeBlacklisted()
    local ok, m = pcall(require, "client.logic.lobby.hall_theme_utils")
    if not ok or not m then return false end
    local curItem = tonumber(m.homeThemeItemId) or 0
    if _VEH_REFRESH_THEME_BLACKLIST[curItem] then return true end
    local curInst = tonumber(m.homeThemeInstId) or 0
    if _VEH_REFRESH_THEME_BLACKLIST[curInst] then return true end
    return false
end

-- 是否在车库展示主题（全局标记兜底，避免首次 require 失败误判）
local function _IsInGarageTheme()
    if _G.__inGarageThemeActive then return true end
    local ok, r = pcall(function()
        local MM = require("client.module_framework.ModuleManager")
        local GTS = MM.GetModule(MM.LobbyModuleConfig.GarageThemeSystem)
        if GTS and GTS.IsInGarageTheme then
            return GTS:IsInGarageTheme() == true
        end
        return false
    end)
    return ok and r == true
end

-- ========== 扫描大厅展示载具 ==========
function _G.LobbyVehicleRefresh()
    pcall(function()
        -- ★ 黑名单主题：完全跳过
        if _IsThemeBlacklisted() then
            return
        end
        -- ★ 车库展示主题：完全跳过
        if _IsInGarageTheme() then
            return
        end

        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return end
        local UGS = import("GameplayStatics")
        if not UGS then return end

        local classes = { "STExtraLobbyVehicle", "STExtraVehicleBase", "BattleVehicleBase" }
        for _, cname in ipairs(classes) do
            local ok, cls = pcall(import, cname)
            if ok and cls then
                local ok2, arr = pcall(function()
                    return UGS.GetAllActorsOfClass(world, cls, {})
                end)
                if ok2 and arr then
                    for i = 0, arr:Num() - 1 do
                        local v = arr:Get(i)
                        if slua.isValid(v) then
                            _G._ApplyVehicleSkinToActor(v)
                        end
                    end
                end
            end
        end
    end)
end

    -- ========== 包装用户切换皮肤入口 ==========
-- ★ DazhiMH_Config 在文件末尾才定义，这里直接 hook 会失败，改成延迟重试
local function _tryHookDazhiConfig()
    local C = _G.DazhiMH_Config
    if not C or type(C.ApplyVehicleSkin) ~= "function" then return false end
    if C.__wmLobbyVehWrapped then return true end
    C.__wmLobbyVehWrapped = true

    local orig = C.ApplyVehicleSkin
    C.ApplyVehicleSkin = function(vehicleKey, index)
        local r = orig(vehicleKey, index)
        _G.__LobbyVehSkinCache = {}
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(0.1, function()
                pcall(_G.LobbyVehicleRefresh)
            end)
        end
        return r
    end
    print("[Vehicle] ApplyVehicleSkin Hook 已挂上")
    return true
end

if not _tryHookDazhiConfig() then
    local _retry = 0
    local function _loopRetry()
        _retry = _retry + 1
        if _tryHookDazhiConfig() then return end
        if _retry >= 30 then return end
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(1, _loopRetry)
        end
    end
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(1, _loopRetry)
    end
end

    -- ========== 启动 ==========
if _G.Mytimer_ticker then
    local _wasInLobby = false
    local _wasInGame = false
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(function()
            local inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity
                and GameStatus.IsInLobbyOrMainCity() == true
            local inGame = GameStatus and GameStatus.IsInFightingStatus
                and GameStatus.IsInFightingStatus() == true

            -- 进大厅：清缓存 + 2 秒 / 5 秒各刷一次（等角色重建完成）
            if inLobby and not _wasInLobby then
                _wasInLobby = true
                _G.__LobbyVehSkinCache = {}
                _G.Mytimer_ticker.AddTimer(2.0, function() pcall(_G.LobbyVehicleRefresh) end)
                _G.Mytimer_ticker.AddTimer(5.0, function() pcall(_G.LobbyVehicleRefresh) end)
            elseif not inLobby then
                _wasInLobby = false
            end

            -- ★★★ 退出对局回大厅：1 秒 / 3 秒各补刷一次（防载具消失） ★★★
            if _wasInGame and not inGame and inLobby then
                _G.__LobbyVehSkinCache = {}
                _G.Mytimer_ticker.AddTimer(1.0, function() pcall(_G.LobbyVehicleRefresh) end)
                _G.Mytimer_ticker.AddTimer(3.0, function() pcall(_G.LobbyVehicleRefresh) end)
            end
            _wasInGame = inGame
        end)
    end, -1, 1)
end
end



-- ==================== 击杀统计 ====================
_G.killCountInfo = _G.killCountInfo or {}

function _G.getKills(weaponID)
    return weaponID and _G.killCountInfo[weaponID] or 0
end

function _G.loadKillCountFromFile()
    local possibleLoadPaths = {
        "/storage/emulated/0/Android/obb/com.tencent.ig/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.krmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.vng.pubgmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.rekoo.pubgm/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.imobile/JSQ.txt",
    }
    
    local killCountPath = nil
    for _, path in ipairs(possibleLoadPaths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            killCountPath = path
            break
        end
    end
    
    if not killCountPath then return end
    
    local file = io.open(killCountPath, "r")
    if not file then return end
    
    local content = file:read("*all")
    file:close()
    
    if content == "" then return end
    
    local tempTable = {}
    for weaponID, count in content:gmatch("%[(%d+)%]%s*=%s*(%d+)") do
        tempTable[tonumber(weaponID)] = tonumber(count)
    end
    
    if next(tempTable) then
        _G.killCountInfo = tempTable
    end
end

function _G.addKill(weaponID, count)
    if not weaponID or not count then return end
    _G.killCountInfo[weaponID] = (_G.killCountInfo[weaponID] or 0) + count
    
    local killCountPath = nil
    local possibleSavePaths = {
        "/storage/emulated/0/Android/obb/com.tencent.ig/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.krmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.vng.pubgmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.rekoo.pubgm/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.imobile/JSQ.txt",
    }
    
    for _, path in ipairs(possibleSavePaths) do
        local file = io.open(path, "a")
        if file then
            file:close()
            killCountPath = path
            break
        end
    end
    
    if killCountPath then
        local file = io.open(killCountPath, "w")
        if file then
            file:write("{\n")
            for wid, kills in pairs(_G.killCountInfo) do
                file:write(string.format("    [%d] = %d,\n", wid, kills))
            end
            file:write("}")
            file:close()
        end
    end
end






-- ==================== 击杀信息颜色修改 ====================
local KillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
if KillInfo and KillInfo.__inner_impl then
    local o_UpdateColorLua = KillInfo.__inner_impl.UpdateColorLua
    KillInfo.__inner_impl.UpdateColorLua = function(self, RelationShip, WeaponAvatarID, IsUseColor, UseColor)
        if o_UpdateColorLua then
            o_UpdateColorLua(self, RelationShip, WeaponAvatarID, IsUseColor, UseColor)
        end
        
        -- 判断是否为自己的击杀（Relationship = 0 表示自己击杀）
        -- RelationShip: 0=自己击杀, 1=队友击杀, 2=敌人击杀
        local isSelfKill = (RelationShip == 0)
        
        if isSelfKill and self.Image_WeaponIcon then
            -- 只有自己的击杀才显示金色
            local GoldColor = FLinearColor(1, 0.8, 0, 1)  -- 金色
            self.Image_WeaponIcon:SetColorAndOpacity(GoldColor)
        elseif self.Image_WeaponIcon then
            -- 别人的击杀恢复默认颜色（白色/原色）
            local WhiteColor = FLinearColor(1, 1, 1, 1)  -- 白色
            self.Image_WeaponIcon:SetColorAndOpacity(WhiteColor)
        end
    end
end



-- ==================== 击杀信息Hook ====================
local SKillInfoModuleManager = require("client.module_framework.ModuleManager")
local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local O_FileItem = SKillInfo.__inner_impl.FileItem
local ECharacterHealthStatus = import("ECharacterHealthStatus")

SKillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
    if not self or not DamageRecordData then return end
    local LogicKillCounter = SKillInfoModuleManager.GetModule(SKillInfoModuleManager.CommonModuleConfig.LogicKillCounter)
    if not LogicKillCounter then return O_FileItem(self, DamageRecordData) end
    local uCharacter = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() and
                           slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    if not uCharacter or not slua.isValid(uCharacter) then return O_FileItem(self, DamageRecordData) end
    local SelfName = uCharacter:GetPlayerNameSafety()
    
    -- 载具击杀处理
    if DamageRecordData.DamageType == UEnums.DamageType.VehicleDamage then
        local VehicleSkinID = _G.CurrentEquipVehicleID or 0
        if VehicleSkinID ~= 0 then
            local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
            ExpandData.CauserVehicleSkinID = VehicleSkinID
            DamageRecordData.CauserWeaponAvatarID = VehicleSkinID
            DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
        end
        return O_FileItem(self, DamageRecordData)
    end
    
    if DamageRecordData.Causer == SelfName then
    local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
    local currWeapon = uCharacter:GetCurrentWeapon()
    if currWeapon and slua.isValid(currWeapon) then
        local DefineID = currWeapon:GetItemDefineID() and currWeapon:GetItemDefineID().TypeSpecificID or 0
        if DefineID ~= 0 then
            local baseWeaponID = _G.getBaseWeaponID(DefineID)  -- ✅ 添加这行：1010042 -> 101004
            local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  -- ✅ 改用 baseWeaponID
            if SupportKillCounter and DamageRecordData.ResultHealthStatus == ECharacterHealthStatus.FinishedLastBreath then
                ExpandData.KillCounterItemId = DefineID
                ExpandData.KillCounterNum = (ExpandData.KillCounterNum or 0) + 1
                _G.addKill(DefineID, 1)  -- 仍然用皮肤ID存储
            end
            _G.UpdateMyKillCounter = true
			--DamageRecordData.CauserClothAvatarID = 1407512
			DamageRecordData.CauserClothAvatarID = _G.SuitSkin or 1407512
            DamageRecordData.CauserWeaponAvatarID = _G.get_skin_id2(DefineID)
            DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
        end
    end
end
    O_FileItem(self, DamageRecordData)
end



-- ==================== 计数器UI ====================
local MyMainKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainKillCounter")
local MyKillCountSubSystem = require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
local MyMainWeaponInfoItemUI = require("GameLua.Mod.BaseMod.Client.Backpack.MainWeaponInfoItemUI")
local MyMainWeaponKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainWeaponKillCounter")
local SlotBase = require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
local MainCGUIManager = require("client.slua_ui_framework.manager")

function _G.GameAvatarHandlerkillcounter()
    local PlayerController = slua_GameFrontendHUD:GetPlayerController()
    if not PlayerController then return end
    
    local uCharacter = PlayerController:GetPlayerCharacterSafety()
    if not uCharacter then return end
    
    local currweapon = uCharacter:GetCurrentWeapon()
    if not currweapon then
        local MainKillCounter = MainCGUIManager.GetUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        if MainKillCounter then
            MainCGUIManager.CloseUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        end
        return
    end
    
    local weaponID = currweapon:GetItemDefineID().TypeSpecificID
    local baseWeaponID = _G.getBaseWeaponID(weaponID)
    local skinID = _G.get_skin_id2(weaponID)
    
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local SupportKillCounter = LogicKillCounter and LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)
    local hasSkin = skinID and skinID ~= baseWeaponID
    
    if SupportKillCounter and hasSkin then
        _G.WeaponEvents.onWeaponChanged(baseWeaponID)
    else
        local MainKillCounter = MainCGUIManager.GetUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        if MainKillCounter then
            MainCGUIManager.CloseUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        end
    end
end

_G.WeaponEvents = _G.WeaponEvents or { onWeaponChanged = function() end }
_G.UpdateMyKillCounter = false

_G.WeaponEvents.onWeaponChanged = function(weaponId)
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then return end
    local uCharacter = pc:GetPlayerCharacterSafety()
    if not uCharacter or not slua.isValid(uCharacter) then return end
    if not _G.OurkillCountSystem then return end

    local currweapon = uCharacter:GetCurrentWeapon()
    if not currweapon then return end

    local DefineID = currweapon:GetItemDefineID().TypeSpecificID
    local SkinID = _G.get_skin_id2(DefineID)
    
    _G.UpdateMyKillCounter = false
    _G.OurkillCountSystem:UpdateMainKillCounterUI(true, DefineID, SkinID)
end

-- 修复OnRefreshUI
-- 修复OnRefreshUI
local o_OnRefreshUI = MyMainKillCounter.__inner_impl.OnRefreshUI
MyMainKillCounter.__inner_impl.OnRefreshUI = function(self, _, _, UID)
    if o_OnRefreshUI then
        o_OnRefreshUI(self, _, _, UID)
    end
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local uCharacter = slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    local currweapon = uCharacter:GetCurrentWeapon()
    if currweapon ~= nil then
        local DefineID = currweapon:GetItemDefineID().TypeSpecificID
        local baseWeaponID = _G.getBaseWeaponID(DefineID)  -- 添加这行
        local SkinID = _G.get_skin_id2(DefineID)
        local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, baseWeaponID)  -- 改用 baseWeaponID
        if self.KillCounterItem then
            self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
        end
    end
end

-- 修复UpdateMainKillCounterUI
-- 修复UpdateMainKillCounterUI
local o_UpdateMainKillCounterUI = MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI
MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
    local UIManager = require("client.slua_ui_framework.manager")
    local MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
    local uCharacter = slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    local currweapon = uCharacter:GetCurrentWeapon()
 
    if not bShow and MainKillCounter then
        UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
    elseif bShow and currweapon ~= nil then
        local DefineID = currweapon:GetItemDefineID().TypeSpecificID
        local baseWeaponID = _G.getBaseWeaponID(DefineID)  -- 添加这行
        local SkinID = _G.get_skin_id2(DefineID)
        local ModuleManager = require("client.module_framework.ModuleManager")
        local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
        local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  -- 改用 baseWeaponID
        if SupportKillCounter == nil and MainKillCounter then
            UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
        elseif baseWeaponID == SkinID and MainKillCounter then  -- 改用 baseWeaponID
            UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
        else
            local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, SkinID)
            if not MainKillCounter then
                UIManager.ShowUI(UIManager.UI_Config_InGame.MainKillCounter, baseWeaponID, SkinID)  -- 改用 baseWeaponID
                MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                if MainKillCounter and MainKillCounter.SetKillCounterItemShowWithNum then
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
                end
            else
                if MainKillCounter.UpdateWeaponID then
                    MainKillCounter:UpdateWeaponID(baseWeaponID, SkinID)  -- 改用 baseWeaponID
                end
                if MainKillCounter.SetKillCounterItemShowWithNum then
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
                end
            end
        end
    elseif o_UpdateMainKillCounterUI then
        o_UpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID)
    end
end

-- 修复OnRefresh
-- 修复OnRefresh
local o_OnRefresh = MyMainWeaponKillCounter.__inner_impl.OnRefresh
MyMainWeaponKillCounter.__inner_impl.OnRefresh = function(self, SelfUID)
    if o_OnRefresh then
        o_OnRefresh(self, SelfUID)
    end
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local curEquipedKillCounter = LogicKillCounter:GetMyEquipedKillCounterId(_G.get_skin_id2(self.WeaponID))
    if self.KillCounterItem then
        self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(self.WeaponID), _G.get_skin_id2(self.WeaponID))
    end
end

-- 修复UpdateWeaponAppearanceInfo
local o_UpdateWeaponAppearanceInfo = MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo
MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
    if o_UpdateWeaponAppearanceInfo then
        o_UpdateWeaponAppearanceInfo(self, TypeSpecificID, BattleData, DragOrigin)
    end
    if self.UpdateKillCounter then
        self:UpdateKillCounter(true)
    end
end

-- 修复CheckShowKCIcon
local o_CheckShowKCIcon = SlotBase.__inner_impl.CheckShowKCIcon
SlotBase.__inner_impl.CheckShowKCIcon = function(self)
    if o_CheckShowKCIcon then
        o_CheckShowKCIcon(self)
    end
    local ESlateVisibility = import("ESlateVisibility")
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local CurWeapon = self:GetCurrentWeapon()
    if not slua.isValid(CurWeapon) then 
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.Collapsed)
        end
        return 
    end
    
    local WeaponID = CurWeapon:GetWeaponID()
    local baseWeaponID = _G.getBaseWeaponID(WeaponID)  -- 皮肤ID转基础ID
    local skinID = _G.get_skin_id2(WeaponID)           -- 获取自定义皮肤
    local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  -- 用基础ID判断
    local hasSkin = skinID and skinID ~= baseWeaponID   -- 用基础ID判断是否换皮
    
    if SupportKillCounter and hasSkin then
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    else
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end



-- ==================== ★★★ 车库展示系列（支持法拉利/布加迪/兰博基尼） ★★★ ====================
do
    local MM = require("client.module_framework.ModuleManager")
    local mgr = MM.GetModule(MM.LobbyModuleConfig.ThemeVehicleManager)
    local MyGarageThemeSystem = MM.GetModule(MM.LobbyModuleConfig.GarageThemeSystem)

    -- 1. 定义三大系列
    local FERRARI_LIST = {
        1961070, 1961071, 1961072, 1961073, 19116002, 19116003, 19116004
    }
    local BUGATTI_LIST = {
        1961151, 1961152, 1961153, 1961044, 1961045, 1961046, 1961047
    }
    local LAMBORGHINI_LIST = {
        1961144, -- 兰博基尼Invencible嫣红瑰影
        1961145, -- 兰博基尼Invencible浪迹星云
        1903079, -- Lamborghini Estoque 金辉
        1961025, -- Lamborghini Centenario 夜都
        1961021, -- Lamborghini Centenario 银河
        1961020, -- Lamborghini Aventador SVJ 绿野
        1961024, -- Lamborghini Aventador SVJ 魅蓝
    }

    -- 2. 动态读取配置
    local function GetCurrentList()
        local brandMode = 1
        if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
            brandMode = _G.DazhiMH_Config.Get("GARAGE_BRAND", 1)
        end
        local mode = tonumber(brandMode) or 1
        
        if mode == 2 then
            return BUGATTI_LIST
        elseif mode == 3 then
            return LAMBORGHINI_LIST
        else
            return FERRARI_LIST
        end
    end

    -- 3. 拦截车库列表获取
    if MyGarageThemeSystem then
        MyGarageThemeSystem.GetSelfGarageVehicleIDs = function(self)
            return GetCurrentList()
        end
    end

    -- 4. 强行接管模型刷新
    if mgr then
        if not rawget(mgr, "__orig_show") then
            rawset(mgr, "__orig_show", mgr._ShowSelfVehicle)
        end

        mgr._ShowSelfVehicle = function(self)
    if not self then return end
    
    if MyGarageThemeSystem and MyGarageThemeSystem:IsInGarageTheme() then
        -- ★ 维护全局车库标记，供 LobbyVehicleRefresh 使用
        _G.__inGarageThemeActive = true
        -- 暴力清空所有旧模型
        for k, v in pairs(self) do
            if type(v) == "table" then
                for _, actor in pairs(v) do
                    if slua.isValid(actor) and actor.K2_DestroyActor then
                        pcall(function() actor:K2_DestroyActor() end)
                    end
                end
                self[k] = {}
            end
        end

        -- 实时读取最新列表并生成
        local currentList = GetCurrentList()
        local VehicleRefitHandler = require("client.network.Protocol.VehicleRefitHandler")
        for Position, ItemID in ipairs(currentList) do
            local StyleList = VehicleRefitHandler.GetCarStyleList(ItemID, nil, nil) or {}
            pcall(function()
                self:_TryCreateVehicleModel(ItemID, StyleList, true, Position, {}, 7302002, DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
            end)
        end
        pcall(function() self:OnVehicleChange() end)
        return
    end
    
    _G.__inGarageThemeActive = false  -- ★ 不在车库主题，清标记
    -- 大厅逻辑原样交还
    local origShow = rawget(self, "__orig_show")
    if origShow then return origShow(self) end
end
    end                                  -- ★★★ 关键修复：闭合 if mgr then ★★★

    -- 5. 强行注入拥有数据
    local function injectOwnership()
        local currentList = GetCurrentList()
        if _G.AddCustomSkinItem then
            for _, id in ipairs(currentList) do
                pcall(_G.AddCustomSkinItem, id)
            end
        end
        if mgr then
            mgr.homeVehicleItemId = currentList[1]
        end
    end

    if _G.Mytimer_ticker then
    local _lastGarageKey = nil
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(injectOwnership)
        if MyGarageThemeSystem and MyGarageThemeSystem:IsInGarageTheme() and mgr then
            _G.__inGarageThemeActive = true
            -- ★ 只在品牌列表变化时重建（避免每 1 秒重复销毁重建导致闪烁）
            local currentList = GetCurrentList()
            local key = table.concat(currentList, ",")
            if key ~= _lastGarageKey then
                _lastGarageKey = key
                pcall(function() mgr:_ShowSelfVehicle() end)
            end
        else
            _G.__inGarageThemeActive = false
            _lastGarageKey = nil
        end
    end, -1, 1)
end

    -- 6. 吃掉报错
    pcall(function()
        if _G.ShowNotice then
            local orig = _G.ShowNotice
            _G.ShowNotice = function(id, ...)
                if tonumber(id) == 100241007 then return end
                return orig(id, ...)
            end
        end
    end)
end



-- ==================== 伪货币模块 (Fake G Currency) ====================
-- 用于伪造 G币、UC、银币数量显示
if _G.__FakeGCurrency_Loaded then
    _G.__FakeGCurrency_Skipped = true
else
    _G.__FakeGCurrency_Loaded = true
    _G.__FakeGCurrency_Skipped = false
end

-- ========== 设置你要显示的伪货币数量 ==========
local FAKE_G_AMOUNT = 78787878      -- G币数量
local FAKE_UC_AMOUNT = 99999991    -- UC数量  
local FAKE_SILVER_AMOUNT = 78916613 -- 银币数量（商店兑换用）
-- ============================================

local function wrapModule(moduleName, wrapFunc)
    local mod = package.loaded[moduleName]
    if mod then
        wrapFunc(mod)
    else
        package.preload[moduleName] = function()
            package.preload[moduleName] = nil
            local m = require(moduleName)
            wrapFunc(m)
            return m
        end
    end
end

local function hookLogicItemUtils(mod)
    if not mod or not mod.GetItemCount then return end
    local orig = mod.GetItemCount
    mod.GetItemCount = function(nItemId, bForever)
        local result = orig(nItemId, bForever)
        if not nItemId then return result end
        local numId = tonumber(nItemId)
        if numId == 1109 then return FAKE_G_AMOUNT end
        if numId == 1006 then return FAKE_UC_AMOUNT end
        if numId == 1001 then return FAKE_SILVER_AMOUNT end
        -- ★ 必须每次 require：logic_shop 首次加载有初始化副作用
        local ok, ShopSystem = pcall(require, "client.logic.shop.logic_shop")
        if ok and ShopSystem and ShopSystem.jkActivePrice and ShopSystem.jkActivePrice.couponId then
            if numId == tonumber(ShopSystem.jkActivePrice.couponId) then
                return FAKE_G_AMOUNT
            end
        end
        return result
    end
end

local function hookMallSystem(mod)
    if not mod or not mod.GetItemCountInBag then return end
    local orig = mod.GetItemCountInBag
    mod.GetItemCountInBag = function(item_id)
        local result = orig(item_id)
        if not item_id then return result end
        local numId = tonumber(item_id)
        if numId == 1109 then return FAKE_G_AMOUNT end
        if numId == 1006 then return FAKE_UC_AMOUNT end
        if numId == 1001 then return FAKE_SILVER_AMOUNT end
        -- ★ 必须每次 require：logic_shop 首次加载有初始化副作用
        local ok, ShopSystem = pcall(require, "client.logic.shop.logic_shop")
        if ok and ShopSystem and ShopSystem.jkActivePrice and ShopSystem.jkActivePrice.couponId then
            if numId == tonumber(ShopSystem.jkActivePrice.couponId) then
                return FAKE_G_AMOUNT
            end
        end
        return result
    end
end

local function hookStoreUtils()
    pcall(function()
        local StoreUtils = require("client.slua.logic.store.utils.store_utils")
        if not StoreUtils or not StoreUtils.GetMoneyInfo then return end
        if StoreUtils.__fakeMoneyHooked then return end
        StoreUtils.__fakeMoneyHooked = true
        local orig = StoreUtils.GetMoneyInfo
        StoreUtils.GetMoneyInfo = function()
            local info = orig()
            info.nDiamond = FAKE_G_AMOUNT
            info.nUC = FAKE_UC_AMOUNT
            info.nSilver = FAKE_SILVER_AMOUNT
            return info
        end
    end)
end

if not _G.__FakeGCurrency_Skipped then
pcall(function()
    wrapModule("client.slua.logic.common.Logic_ItemUtils", hookLogicItemUtils)
    wrapModule("client.logic.mall.logic_mall", hookMallSystem)
    hookStoreUtils()
    if DataMgr then
        DataMgr.eternal_diamond = FAKE_G_AMOUNT
        DataMgr.ticket = FAKE_UC_AMOUNT
        DataMgr.diamond = FAKE_SILVER_AMOUNT
    end
    if EventSystem and EVENTTYPE_DATA_MGR then
        local ev = _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE
        if ev then EventSystem:postEvent(EVENTTYPE_DATA_MGR, ev, FAKE_G_AMOUNT) end
        local evUC = _G.EVENTID_DATAMGR_TICKET_CHANGE
        if evUC then EventSystem:postEvent(EVENTTYPE_DATA_MGR, evUC, FAKE_UC_AMOUNT) end
        local evD = _G.EVENTID_DATAMGR_DIAMOND_CHANGE
        if evD then EventSystem:postEvent(EVENTTYPE_DATA_MGR, evD, FAKE_SILVER_AMOUNT) end
    end
    print("[FakeGCurrency] 已加载 - G=" .. FAKE_G_AMOUNT .. " UC=" .. FAKE_UC_AMOUNT .. " Silver=" .. FAKE_SILVER_AMOUNT)
end)
end -- if not _G.__FakeGCurrency_Skipped

-- 使用定时器持续刷新（配合现有定时器系统）
if _G.Mytimer_ticker then
    _G.Mytimer_ticker.AddTimerLoop(3, function()
        pcall(function()
            if DataMgr then
                DataMgr.eternal_diamond = FAKE_G_AMOUNT
                DataMgr.ticket = FAKE_UC_AMOUNT
                DataMgr.diamond = FAKE_SILVER_AMOUNT
            end
            if EventSystem and EVENTTYPE_DATA_MGR then
                if _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE, FAKE_G_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_TICKET_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_TICKET_CHANGE, FAKE_UC_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_DIAMOND_CHANGE, FAKE_SILVER_AMOUNT)
                end
            end
        end)
    end, -1, 1)
elseif _G.SetTimer then
    _G.SetTimer(3, function()
        pcall(function()
            hookStoreUtils()
            if DataMgr then
                DataMgr.eternal_diamond = FAKE_G_AMOUNT
                DataMgr.ticket = FAKE_UC_AMOUNT
                DataMgr.diamond = FAKE_SILVER_AMOUNT
            end
            if EventSystem and EVENTTYPE_DATA_MGR then
                if _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE, FAKE_G_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_TICKET_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_TICKET_CHANGE, FAKE_UC_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_DIAMOND_CHANGE, FAKE_SILVER_AMOUNT)
                end
            end
        end)
    end)
end

_G.FakeGCurrency = { Amount = FAKE_G_AMOUNT, UC = FAKE_UC_AMOUNT, Silver = FAKE_SILVER_AMOUNT }
function _G.FakeGCurrency.OnLogin() end


-- ==================== 手机状态栏文字自定义 ====================
-- 此模块用于在游戏画面上方显示自定义文字
pcall(function()
    -- ========== 新增：水印开关（从配置文件读取） ==========
local function IsWatermarkEnabled()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("WATERMARK", 0)  -- 默认 0=关闭
    end
    return configValue == 1
end
    -- ====================================================
    
    local CUSTOM_TEXT = "楪祈频道@yeqizpd"
    local FONT_SIZE = 12.5
    local TEXT_SCALE = 1.0
    local TEXT_OFFSET_X = 0
    local TEXT_OFFSET_Y = 0
    local applyCount = 0
    
    -- 缓存开关状态
    local _watermarkEnabled = IsWatermarkEnabled()

    local function hideWidget(widget)
        if not widget then return end
        local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
        if widget.SetWidgetVisibility and vis then
            pcall(function() widget:SetWidgetVisibility(vis.Collapsed) end)
        end
        if widget.SetRenderOpacity then
            pcall(function() widget:SetRenderOpacity(0) end)
        end
    end

    local function applyTextStyle(tb, vis)
        -- ========== 开关检查 ==========
        _watermarkEnabled = IsWatermarkEnabled()
        if not _watermarkEnabled then
            -- 如果开关关闭，隐藏控件
            if tb and tb.SetWidgetVisibility and vis then
                pcall(function() tb:SetWidgetVisibility(vis.Collapsed) end)
            end
            return
        end
        -- ==============================
        
        if not tb then return end
        if tb.SetWidgetVisibility and vis then tb:SetWidgetVisibility(vis.SelfHitTestInvisible) end
        if tb.SetText then tb:SetText(CUSTOM_TEXT) end
        if tb.SetColorAndOpacity then
            local PinkColor = FSlateColor(FLinearColor(25.0, 0, 0, 1))--color = { R = 25.0, G = 0.0, B = 0.0, A = 1.0 }   -- 红色（可见）
            tb:SetColorAndOpacity(PinkColor)
        end
        pcall(function()
            if tb.SetRenderScale then tb:SetRenderScale(FVector2D(TEXT_SCALE, TEXT_SCALE)) end
        end)
        pcall(function()
            local font = tb.Font
            if font then font.Size = FONT_SIZE end
            if tb.SetFont and font then tb:SetFont(font) end
        end)
        pcall(function()
            local ETextJustify = import("ETextJustify")
            if ETextJustify and tb.SetJustification then tb:SetJustification(ETextJustify.Right) end
        end)
        pcall(function()
            local slot = tb.Slot
            if slot and slot.SetPosition then slot:SetPosition(FVector2D(TEXT_OFFSET_X, TEXT_OFFSET_Y)) end
        end)
    end

    local function applyCustomText()
        applyCount = applyCount + 1
        pcall(function()
            local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
            if not vis then return end

            pcall(function()
                local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                if InGameUITools and InGameUITools.GetMainControlBaseUI then
                    local MainUI = InGameUITools.GetMainControlBaseUI()
                    if MainUI then
                        hideWidget(MainUI.TextBlock_BID)
                        applyTextStyle(MainUI.TextBlock_Hour, vis)
                    end
                end
            end)

            if UIManager and UIManager.UI_Config_InGame and UIManager.UI_Config_InGame.BIDHourUI then
                local BIDUI = UIManager.GetUI(UIManager.UI_Config_InGame.BIDHourUI)
                if BIDUI and BIDUI.UIRoot then
                    hideWidget(BIDUI.UIRoot.TextBlock_BID)
                    applyTextStyle(BIDUI.UIRoot.TextBlock_Hour, vis)
                end
            end
        end)
    end

    -- 使用现有的定时器系统
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(2, function()
            pcall(applyCustomText)
        end, -1, 1)
    elseif _G.SetTimer then
        _G.SetTimer(3, applyCustomText)
    else
        -- 备用：自循环
        local function loopTimer()
            applyCustomText()
            if applyCount < 10000 then
                local ok, tt = pcall(require, "common.time_ticker")
                if ok and tt and tt.AddTimer then
                    tt.AddTimer(1, loopTimer)
                end
            end
        end
        loopTimer()
    end
end)

_G.PhoneStateTextChanger = {
    SetText = function(text) 
    if text then
        pcall(function()
                local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
                local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                local MainUI = InGameUITools and InGameUITools.GetMainControlBaseUI()
                if MainUI and MainUI.TextBlock_Hour then
                    MainUI.TextBlock_Hour:SetText(text)
                end
            end)
        end
    end,
    GetText = function() return "WeWeLola" end,
}


--[[
-- ==================== 文字修改 ====================
pcall(function()
    local IngamePhoneStateUI = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
    if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl then
        local o_UpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI
        IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self)
            o_UpdateArtQualityUI(self)
            if self.UIRoot and self.UIRoot.TextBlock_quality then
                self.UIRoot.TextBlock_quality:SetText("@yeqizpd")
                self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0.4, 0.7, 1)))
            end
        end
    end
end)

pcall(function()
    local Lobby_Main_Wifi_UIBP = require("client.slua.umg.lobby.Main.Lobby_Main_Wifi_UIBP")
    if Lobby_Main_Wifi_UIBP and Lobby_Main_Wifi_UIBP.__inner_impl then
        local o_UpdateQuality = Lobby_Main_Wifi_UIBP.__inner_impl.UpdateQuality
        Lobby_Main_Wifi_UIBP.__inner_impl.UpdateQuality = function(self)
            o_UpdateQuality(self)
            if self.UIRoot and self.UIRoot.TextBlock_High then
                self.UIRoot.TextBlock_High:SetText("@yeqizpd")
                self.UIRoot.TextBlock_High:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0.4, 0.7, 1)))
            end
        end
    end
end)
]]

-- ==================== 背包UI刷新 ====================
local WeaponInfoItemBase = require("GameLua.Mod.BaseMod.Client.Backpack.WeaponInfoItemBase")
local o_UpdateWeaponAppearanceInfoBase = WeaponInfoItemBase.__inner_impl.UpdateWeaponAppearanceInfo

WeaponInfoItemBase.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
    if not TypeSpecificID then
        return o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    end
    
    local ItemData = CDataTable.GetTableData("Item", TypeSpecificID)
    if not ItemData then
        return o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    end
    
    local skin_id = TypeSpecificID
    if _G.weaponTypes and _G.weaponTypes[TypeSpecificID] == ModItemType.PISTOL_SKINS then
        o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    else
        skin_id = _G.get_skin_id2 and _G.get_skin_id2(TypeSpecificID) or TypeSpecificID
        o_UpdateWeaponAppearanceInfoBase(self, skin_id, BattleData, DragOrigin)
    end
    
    local PC = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not PC then return end
    local uCharacter = PC:GetPlayerCharacterSafety()
    if not uCharacter then return end
    local WeaponManager = uCharacter:GetWeaponManager()
    if not WeaponManager then return end
    
    local WeaponList = WeaponManager:GetAllInventoryWeaponList(false)
    if not WeaponList then return end
    
    for i = 0, WeaponList:Num() - 1 do
        local CurWeapon = WeaponList:Get(i)
        if CurWeapon and CurWeapon:GetWeaponID() == TypeSpecificID then
            if self.UIRoot and self.UIRoot.TextBlock_WeaponName then
                self.UIRoot.TextBlock_WeaponName:SetText(ItemData.ItemName)
            end
            self.TypeSpecificIDTemp = TypeSpecificID
            self.ItemID = TypeSpecificID
            if self.UIRoot then
                self.UIRoot.ItemID = TypeSpecificID
            end
            self:BindWeaponChangeEvent()
            self:UpdateBullet()
            self:UpdateWeaponDurability()
            self:UpdateWeaponAttachment()
            break
        end
    end
end

-- 刷新背包面板武器显示
local function UpdateWeaponBackpackAppearance(PlayerController)
    if not PlayerController then return end
    local Simplemanager = require("client.slua_ui_framework.manager")
    if not Simplemanager then return end
    local BackPackPanelUI = Simplemanager.GetUI(Simplemanager.UI_Config_InGame.BackPackPanelUI)
    if not BackPackPanelUI then return end
    local BackpackComp = PlayerController:GetBackpackComponent()
    if not BackpackComp then return end
    local BackpackUtils = import("BackpackUtils")
    if not BackpackUtils then return end
    local Weapons = BackpackUtils.GetWeaponsInBackpack(BackpackComp)
    if Weapons then
        BackPackPanelUI:UpdateWeaponItems(Weapons)
    end
end

_G.UpdateWeapon_BackPack_Appearance = UpdateWeaponBackpackAppearance

function _G.GameAvatarHandlerBagPack()
    local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if PlayerController then
        _G.UpdateWeapon_BackPack_Appearance(PlayerController)
    end
end

-- ==================== 角色处理函数 ====================
function _G.GameAvatarHandlerplayers()
    local PlayerController = slua_GameFrontendHUD:GetPlayerController()
    if PlayerController then
        if PlayerController.HiggsBoson then
            PlayerController.HiggsBoson.bMHActive = false
            PlayerController.HiggsBoson.bCallPreReplication = false
        end
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if uCharacter then
            _G.equip_character_avatar(uCharacter)
            if uCharacter.bDead and _G.OurkillCountSystem then
                _G.OurkillCountSystem:UpdateMainKillCounterUI(false)
            end
        end
    end
end





-- ==================== 广角相机功能 ====================
function _G.GameCameraView()
    -- ========== 开关检查 ==========
    if not _G.ConfigFOVEnable then
        return  -- 如果开关关闭，直接返回不执行
    end
    -- ==============================
    
    local desiredFOV = _G.ConfigFOV or 110
    
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local uCharacter = GameplayData.GetPlayerCharacter()
    
    if not slua.isValid(uCharacter) then
        return
    end

    -- FPP 第一人称相机
    local CameraComponentFPP = uCharacter:GetFPPCamera()
    if slua.isValid(CameraComponentFPP) then
        CameraComponentFPP:SetFieldOfView(desiredFOV)
    end

    -- Third Person 第三人称相机
    local CameraComponentThird = uCharacter:GetThirdPersonCamera()
    if slua.isValid(CameraComponentThird) then
        CameraComponentThird:SetFieldOfView(desiredFOV)
    end
end


-- ==================== 伪装封禁配置 ====================
function _G.FakeBanSetup()
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager then return end
        
        local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
        if logic_profile then
            logic_profile.IsPlayerBanned = function(uid) return true end
            logic_profile.IsPlayerBannedOver30day = function(uid) return true end
            logic_profile.IsPlayerChatBanned = function(uid) return true end
        end
        
        local ui = require("client.slua_ui_framework.manager").GetUI(
            require("client.slua_ui_framework.manager").UI_Config.Lobby_Main_UIBP
        )
        if ui and ui.Common_Avatar_BP then
            ui.Common_Avatar_BP:SetPlayerBanned(true)
        end
        
        require("client.slua.event.EventSystem"):postEvent(2, 10001)
    end)
end




-- ==================== 表情系统扩展（解锁所有表情） ====================
-- 功能：让你可以使用未拥有的表情，在游戏内和大厅都能用

-- 引用游戏的表情相关模块
local QuickExpressionUtils_Extra = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")  -- 局内表情工具
local Expression_Util_Extra = require("client.slua.umg.Souvenirs.Expression_Util")  -- 大厅表情工具
local BackpackUtils_Extra = import("BackpackUtils")  -- 背包工具

-- ========== 自定义表情ID列表（你想要解锁的表情） ==========
_G.__EXTRA_EMOTE_IDS = {
  12219309, -- 绿洲武士
  12220470, -- 炎剑破晓
  12220401, -- 金芒圣裁
  12220413, -- 黄泉之怒
  12220228, -- 飞旋魔面
  12201301, -- 哥特刺客
  12219207, -- 天牛大将
  12210001, -- 死神之触
  12210801, -- 银壳猎人
  12212601, -- 神秘杀戮
  12205601, -- 巨兽之魂
  12219208, -- 赛博猴王
  2200901,  -- 投降
  12220475, -- 月影绝刃
  12220446, -- 人变巨人
  12220412, -- 生死契约
  12219819, -- 炽焰绯狐
  12220288, -- 紫焰冥驹
  12216101, -- 血鹰武士
  12209001, -- 武士
  12219022, -- 荆棘铁卫
  12200701, -- 时空漫游
  12206001, -- 绿野花灵
  12206801, -- 神秘海龙
  2203601,  -- 威胁（嘲讽）
  12220543, -- 极地冥王
  12220441, -- 仰天吐息
  12220407, -- 裂刃破晓
  12219814, -- 凛冬冰后
  12212201, -- 极暗刺客
  12219561, -- 猩红披风
  12208801, -- 半神勇士
  12219242, -- 苍穹漫步
  12205401, -- 万兽之王
  12205201, -- 巨兽之心
  12209801, -- 御灵师
  12220028, -- 玲珑白蛇
  12204601, -- 天下布武
  2200401,  -- 大笑
  12200801, -- 吹口哨
  12204001, -- 愚人小丑
  12220082, -- 炽烈之魂
  12220126, -- 暗烬天使
  12220049, -- 神域金皇
  12219501, -- 地狱正午
  12219286, -- 寒冰降临
  12219053, -- 瑰宝皇后
  12215502, -- 寂灭之眠
  12220950, -- 爱神商城
12220951, -- 爱神入队
12220952, -- 爱神集结
12220953, -- 爱神集结loop
12220954, -- 魔心爱神
12220965,
}

-- ========== 辅助函数：构建表情数据结构 ==========

-- 构建局内表情数据（给比赛时用）
local function BuildEmoteItem_Extra(nEmoteID)
  local uItemCfg = CDataTable.GetTableData("Item", nEmoteID)  -- 从配置表读取表情信息
  return {
    DefineID = {TypeSpecificID = nEmoteID},  -- 表情ID
    Name = uItemCfg and uItemCfg.ItemName or tostring(nEmoteID)  -- 表情名称
  }
end

-- 构建大厅表情数据
local function BuildLobbyEmoteItem_Extra(nEmoteID)
  return {itemId = nEmoteID}
end

-- 检查表情资源是否已下载
local function IsEmoteAssetOnDevice_Extra(nEmoteID)
  local itemDefineID = FItemDefineID(22, nEmoteID)  -- 22是表情类型
  return BackpackUtils_Extra.IsBattleItemHandleExist(itemDefineID, true, false, false)
end

-- ========== 局内表情注入（比赛对局中） ==========

-- 精简表情列表（去掉无效数据）
local function CompactEmoteList_Extra(showList)
  local compact = {}
  if showList then
    for _, data in pairs(showList) do
      if data and data.DefineID and data.DefineID.TypeSpecificID then
        table.insert(compact, data)
      end
    end
  end
  return compact
end

-- 把自定义表情注入到表情列表
local function InjectExtraEmotes_Extra(showList)
  local result = CompactEmoteList_Extra(showList)  -- 先获取原本的表情列表
  local seen = {}
  
  -- 记录已有的表情ID，避免重复添加
  for _, data in ipairs(result) do
    seen[data.DefineID.TypeSpecificID] = true
  end
  
  -- 遍历自定义表情列表，把没添加的加进去
  for _, nEmoteID in ipairs(_G.__EXTRA_EMOTE_IDS or {}) do
    if nEmoteID and nEmoteID > 0 and not seen[nEmoteID] then
      table.insert(result, BuildEmoteItem_Extra(nEmoteID))
      seen[nEmoteID] = true
      print(bWriteLog and string.format("[ExtraEmote] ingame inject id=%s", tostring(nEmoteID)))
    end
  end
  return result
end

-- 获取完整表情列表（带自定义）
local function GetFullEmoteList_Extra()
  return InjectExtraEmotes_Extra(QuickExpressionUtils_Extra.GetShowExpressionList())
end

-- 强制刷新表情轮盘菜单
local function ForceDrawExpressionMenu_Extra(subPanel)
  if not subPanel or not subPanel.GetQuickExpressionDecalItemByIndex then
    return false
  end
  
  local emoteList = GetFullEmoteList_Extra()
  if not emoteList then return false end
  
  local showCount = 0
  for _, data in ipairs(emoteList) do
    local nEmoteID = data.DefineID and data.DefineID.TypeSpecificID
    if nEmoteID and nEmoteID > 0 then
      showCount = showCount + 1
      local item = subPanel:GetQuickExpressionDecalItemByIndex(showCount)
      if item then
        -- 隐藏特效和武器图标
        if item.UIRoot.WidgetSwitcher_Effect then
          item.UIRoot.WidgetSwitcher_Effect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if item.UIRoot.Image_Weapon then
          item.UIRoot.Image_Weapon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        item:Show()
        item:RefreshData(nEmoteID, -1)  -- 刷新表情数据
      end
    end
  end
  
  -- 隐藏多余的空位
  if subPanel.HideRestBlocks then
    subPanel:HideRestBlocks(showCount)
  end
  
  -- 显示表情列表，隐藏空状态
  if subPanel.UIRoot then
    subPanel.UIRoot.WrapBox_List:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    subPanel.UIRoot.VerticalBox_Empty:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  return true
end

-- 获取局内表情面板
local function GetInGameSubPanel_Extra()
  if not UIManager or not UIManager.UI_Config_InGame then
    return nil
  end
  return UIManager.GetUI(UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel)
end

-- 安装表情面板的Hook（替换刷新函数）
local function InstallSubPanelHook_Extra(subPanel)
  if not subPanel or subPanel.__EXTRA_FORCE_DRAW_HOOKED then
    return
  end
  subPanel.__EXTRA_FORCE_DRAW_HOOKED = true
  
  local origRefreshExpression = subPanel.RefreshExpression
  subPanel.RefreshExpression = function(self)
    if ForceDrawExpressionMenu_Extra(self) then
      return  -- 如果用自定义表情刷新成功，就跳过原函数
    end
    if origRefreshExpression then
      origRefreshExpression(self)
    end
  end
end

-- 尝试刷新局内表情菜单
local function TryRefreshInGameMenu_Extra()
  local subPanel = GetInGameSubPanel_Extra()
  if not subPanel then return false end
  InstallSubPanelHook_Extra(subPanel)
  ForceDrawExpressionMenu_Extra(subPanel)
  return true
end

-- ========== Hook局内表情（拦截游戏原来的获取表情列表函数） ==========
if not _G.__EXTRA_EMOTE_HOOKED_MATCH then
  _G.__EXTRA_EMOTE_HOOKED_MATCH = true
  _G.__EXTRA_EMOTE_ORIG_GET_LIST = QuickExpressionUtils_Extra.GetShowExpressionList
  
  -- 替换原函数，让游戏返回带自定义表情的列表
  function QuickExpressionUtils_Extra.GetShowExpressionList()
    local showList, nWeaponShowEmoteID = _G.__EXTRA_EMOTE_ORIG_GET_LIST()
    return InjectExtraEmotes_Extra(showList), nWeaponShowEmoteID
  end
end

-- 监听表情轮盘点击事件
if not _G.__EXTRA_MENU_EVENT then
  _G.__EXTRA_MENU_EVENT = true
  if EventSystem and EventSystem.registEvent then
    EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK, function()
      local subPanel = GetInGameSubPanel_Extra()
      InstallSubPanelHook_Extra(subPanel)
      ForceDrawExpressionMenu_Extra(subPanel)
    end)
  end
end

-- ========== 大厅表情注入 ==========

-- 把自定义表情注入大厅表情列表
local function InjectLobbyEmotes_Extra(motionList)
  local result = {}
  if motionList then
    for i, item in ipairs(motionList) do
      result[i] = item
    end
  end

  -- 记录已有表情
  local seen = {}
  for _, item in ipairs(result) do
    local id = item and item.itemId
    if id and id > 0 then
      seen[id] = true
    end
  end

  -- 把自定义表情放进空缺位置
  local function PlaceLobbyEmote_Extra(nEmoteID)
    for i, item in ipairs(result) do
      if item.itemId == 0 then
        result[i] = BuildLobbyEmoteItem_Extra(nEmoteID)
        return true
      end
    end
    table.insert(result, BuildLobbyEmoteItem_Extra(nEmoteID))
    return true
  end

  for _, nEmoteID in ipairs(_G.__EXTRA_EMOTE_IDS or {}) do
    if nEmoteID and nEmoteID > 0 and not seen[nEmoteID] then
      PlaceLobbyEmote_Extra(nEmoteID)
      seen[nEmoteID] = true
      print(bWriteLog and string.format("[ExtraEmote] lobby inject id=%s", tostring(nEmoteID)))
    end
  end

  return result
end

-- 获取大厅表情面板
local function GetLobbyExpressionPanel_Extra()
  if not UIManager or not UIManager.UI_Config then
    return nil
  end
  local panel = UIManager.GetUI(UIManager.UI_Config.ExpressionPop_New_UIBP)
  if panel then return panel end
  return UIManager.GetUI(UIManager.UI_Config.TExpressionPop_New_UIBP)
end

-- 尝试刷新大厅表情菜单
local function TryRefreshLobbyMenu_Extra()
  local panel = GetLobbyExpressionPanel_Extra()
  if not panel then return false end
  
  if panel.UpdateActionUI then
    panel:UpdateActionUI()
    return true
  end
  
  if panel.expressList and panel.LoopScrollGrid_Action then
    panel.expressList = Expression_Util_Extra.GetMotionDataList()
    panel.LoopScrollGrid_Action:SetData(panel.expressList)
    return true
  end
  return false
end

-- ========== Hook大厅表情 ==========
if not _G.__EXTRA_EMOTE_HOOKED_LOBBY then
  _G.__EXTRA_EMOTE_HOOKED_LOBBY = true
  _G.__EXTRA_EMOTE_ORIG_GET_MOTION = Expression_Util_Extra.GetMotionDataList
  
  function Expression_Util_Extra.GetMotionDataList()
    return InjectLobbyEmotes_Extra(_G.__EXTRA_EMOTE_ORIG_GET_MOTION())
  end
end

-- Hook打开表情面板的事件
if not _G.__EXTRA_LOBBY_OPEN_HOOKED then
  _G.__EXTRA_LOBBY_OPEN_HOOKED = true
  _G.__EXTRA_LOBBY_ORIG_OPEN = Expression_Util_Extra.OpenExpressionPopUI
  
  function Expression_Util_Extra.OpenExpressionPopUI(actionID)
    _G.__EXTRA_LOBBY_ORIG_OPEN(actionID)
    -- 延迟0.15秒刷新，确保面板已加载
    if slua and slua.Timer and slua.Timer.Add then
      slua.Timer.Add(0.15, function()
        TryRefreshLobbyMenu_Extra()
      end)
    else
      TryRefreshLobbyMenu_Extra()
    end
  end
end

-- ========== 启动（立即执行） ==========
TryRefreshInGameMenu_Extra()   -- 刷新局内表情
TryRefreshLobbyMenu_Extra()    -- 刷新大厅表情

print("[ExtraEmote] 额外表情已加载（大厅+局内）")





--- ==================== 自动添加好友 ====================
-- 这段代码会自动向指定的玩家ID发送好友申请

pcall(function()
    -- 1. 获取好友申请相关的模块
    local logic_profile_get_wrap = require("client.network.Protocol.FriendApplyHandler")
    
    -- 2. 检查模块是否存在，以及是否有自动添加好友的函数
    if logic_profile_get_wrap and logic_profile_get_wrap.on_auto_add_inner_friend_notify then
        
        -- 3. 要添加的好友ID列表（这些应该是作者的账号ID）
        local ids = { 
            523442956, 5587557062, 5818541383, 5249981642, 5216804941, 
            5148652918, 5102101549, 5466455258, 5216953998, 5249175905, 
            559804335, 5194623653, 5143921876, 5120239889, 5586965216,
            5339192620, 5200865910, 5210029111, 5123160209, 5516881460
        }
        
        -- 4. 循环遍历每个ID，发送好友申请
        for _, PlayerID in ipairs(ids) do
            xpcall(function()
                -- 调用内部函数发送好友请求
                logic_profile_get_wrap.on_auto_add_inner_friend_notify(PlayerID)
            end, function(err)
                -- 如果出错，静默处理，不打断循环
            end)
        end
    end
end)

-- ==================== 宠物皮肤处理（局内应用） ====================
function _G.ApplyPetSkinInGame()
    pcall(function()
        local targetId = tonumber(_G.PetSkin) or 0
        -- 如果目标还是 50000，就不管它
        if targetId <= 0 or targetId == 50000 then return end 
        
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end

        local applied = false
        
        -- 暴力强刷函数
        local function forceEquip(actor)
            if not slua.isValid(actor) then return end
            
            -- 1. 遍历组件字典 (Avatar / Mesh / Dress / Pet)
            for k, v in pairs(actor) do
                if type(k) == "string" then
                    local lowerK = k:lower()
                    if lowerK:find("avatar") or lowerK:find("mesh") or lowerK:find("dress") or lowerK:find("pet") then
                        if slua.isValid(v) then
                            if v.RayEquipItemById then pcall(v.RayEquipItemById, v, targetId); applied = true end
                            if v.PetEquipItemById then pcall(v.PetEquipItemById, v, targetId); applied = true end
                            if v.EquipItemById then pcall(v.EquipItemById, v, targetId); applied = true end
                            if v.SetItemID then pcall(v.SetItemID, v, targetId); applied = true end
                            if v.SetAvatarId then pcall(v.SetAvatarId, v, targetId); applied = true end
                            if v.ChangeItemAvatar then pcall(v.ChangeItemAvatar, v, targetId); applied = true end
                        end
                    end
                end
            end
            
            -- 2. 遍历 Actor 自身的方法
            if actor.RayEquipItemById then pcall(actor.RayEquipItemById, actor, targetId); applied = true end
            if actor.ChangeItemAvatar then pcall(actor.ChangeItemAvatar, actor, targetId); applied = true end
            if actor.SetItemID then pcall(actor.SetItemID, actor, targetId); applied = true end
            
            -- ★★★ 3. 核心大招：暴力清洗 50000 残留下来的颜色、材质、配饰数据 ★★★
            if applied or actor.PetId then
                pcall(function()
                    -- 强改 Actor 自身 ID
                    if actor.PetId then actor.PetId = targetId end
                    if actor.PetItemID then actor.PetItemID = targetId end
                    if actor.PetSkinID then actor.PetSkinID = targetId end
                    if actor.SkinID then actor.SkinID = targetId end
                    
                    -- 强清颜色/染色/配饰
                    if actor.PetInfo then
                        actor.PetInfo.PetId = targetId
                        actor.PetInfo.ColorID = 1
                        actor.PetInfo.Color = 1
                        actor.PetInfo.DressData = {}
                    end
                    if actor.PetColorID then actor.PetColorID = 1 end
                    if actor.ColorID then actor.ColorID = 1 end
                    if actor.SkinColorID then actor.SkinColorID = 1 end
                    if actor.PetDressData then actor.PetDressData = {} end
                    if actor.DressData then actor.DressData = {} end
                    
                    -- 触发刷新
                    if actor.RefreshColor then pcall(actor.RefreshColor, actor) end
                    if actor.SetPetColor then pcall(actor.SetPetColor, actor, 1) end
                    if actor.OnRep_PetInfo then pcall(actor.OnRep_PetInfo, actor) end
                    
                    -- 重新触发组件刷新让材质生效
                    local comp = actor.PetAvatarComponent or actor.AvatarComponent
                    if comp and slua.isValid(comp) then
                        if comp.OnRep_AvatarChanged then pcall(comp:OnRep_AvatarChanged()) end
                        if comp.RefreshAvatar then pcall(comp:RefreshAvatar()) end
                    end
                end)
            end
            
            -- 4. 触发引擎级模型重载
            if applied then
                if actor.DelayHandleAvatarMeshChanged then pcall(actor.DelayHandleAvatarMeshChanged, actor) end
                if actor.OnRep_AvatarId then pcall(actor.OnRep_AvatarId, actor) end
                if actor.OnRep_PetInfo then pcall(actor.OnRep_PetInfo, actor) end
                if actor.OnRep_AvatarChange then pcall(actor.OnRep_AvatarChange, actor) end
            end
        end

        -- 途径 A：查找 PetComponent 身上的小机器人
        local petComp = pc.PetComponent
        if slua.isValid(petComp) then
            if slua.isValid(petComp.MiniTvPawn) then forceEquip(petComp.MiniTvPawn) end
            if petComp.GetPetActor then
                local a = petComp:GetPetActor()
                if slua.isValid(a) then forceEquip(a) end
            end
        end

        -- 途径 B：全图扫所有可能的宠类 Actor
        local GameStatics = import("GameplayStatics")
        local world = slua_GameFrontendHUD:GetWorld()
        if slua.isValid(world) then
            local Classes = {
                "MiniTvPawn", "MiniTvCharacter", "STExtraMiniTvCharacter", 
                "LobbyPetCharacter", "FightPetCharacter", "STExtraFightPetCharacter"
            }
            for _, cname in ipairs(Classes) do
                local ok, cls = pcall(import, cname)
                if ok and cls then
                    local ok2, arr = pcall(function() return GameStatics.GetAllActorsOfClass(world, cls, {}) end)
                    if ok2 and arr then
                        for i = 0, arr:Num() - 1 do
                            local actor = arr:Get(i)
                            if slua.isValid(actor) then
                                -- 检查是不是你的宠物
                                local owner = actor.GetOwnerCharacter and actor:GetOwnerCharacter() or actor.Owner
                                if owner == char or actor.PetOwnerPlayerCharacter == char then
                                    forceEquip(actor)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ==================== 宠物皮肤处理（大厅+初始化） ====================
function _G.HandlePetLogic()
    pcall(function()
        if not _G.PetSkinMap or #_G.PetSkinMap == 0 then
            return
        end

        -- ★ 优先使用已经设置好的 _G.PetSkin（来自配置文件 / 滑块），
        --   只有 _G.PetSkin 无效时才用索引兜底（防止覆盖自定义 ID）
        if not _G.PetSkin or _G.PetSkin <= 0 then
            local index = _G.PetSkinMapIndex or 1
            if type(index) ~= "number" then index = 1 end
            if index < 1 or index > #_G.PetSkinMap then index = 1 end
            _G.PetSkin = _G.PetSkinMap[index]
        end

        local applyID = _G.PetSkin

        -- 下载资源（仅当ID变化时下载）
        if applyID ~= _G.LastAppliedPet then
            if not _G.skinIdCache[applyID] then
                _G.download_item(applyID)
                _G.skinIdCache[applyID] = true
            end
        end

        -- ★ Hook 宠物模块（每次 HandlePetLogic 都重挂，防止模块重载后 Hook 丢失）
        local ModuleManager = require("client.module_framework.ModuleManager")
        local logic_pet = ModuleManager and ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)

        if logic_pet then
            logic_pet.GetEquipedPetInsID = function()
                return _G.PetSkin
            end
            logic_pet.GetEquipedPetItemID = function()
                return _G.PetSkin
            end
            logic_pet.GetCurrentCarryPets = function()
                return { _G.PetSkin }
            end
            logic_pet.GetPetDataByInsID = function(_, id)
                if id == _G.PetSkin then
                    return {
                        id = id,
                        ins_id = id,
                        exp = 100000,
                        color = 1,
                        dress = {}
                    }
                end
            end
            logic_pet._hooks_done = true
        end

        -- 刷新大厅宠物显示
        local LobbyAvatarManager = require("client.logic.avatar.LobbyAvatarManager")
        if LobbyAvatarManager and LobbyAvatarManager.CreateMyPet then
            pcall(LobbyAvatarManager.CreateMyPet)
        end

        -- 游戏内初始宠物信息设置
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if pc and slua.isValid(pc) then
    -- ★ 核心修复：千万别覆盖 ID，否则服务器不认滑块 ID，会导致宠物直接消失。
    -- 我们表面上告诉服务器和游戏“我带的还是 50000”，暗地里再偷偷换皮。
    if pc.InitialPetInfo then
        pc.InitialPetInfo.PetId = 50000 
    end
    if pc.PetComponent and slua.isValid(pc.PetComponent) and pc.PetComponent.SetPetID then
        pc.PetComponent:SetPetID(50000)
    end
end

        _G.LastAppliedPet = applyID

        -- 无论ID是否变化，都在局内尝试应用皮肤（防止宠物重生后失效）
        _G.ApplyPetSkinInGame()
    end)
end




-- ==================== RPC拦截 ====================
_G.ProcessEventHooked = false
_G.OriginalProcessEvent = nil

local function SetupProcessEventHook()
    pcall(function()
        local UObject = import("UObject")
        if not UObject or not UObject.ProcessEvent then
            return false
        end
        
        if _G.ProcessEventHooked then
            return true
        end
        
        if not _G.OriginalProcessEvent then
            _G.OriginalProcessEvent = UObject.ProcessEvent
        end
        
        UObject.ProcessEvent = function(self, func, params)
            if not self or not func then
                if _G.OriginalProcessEvent then
                    return _G.OriginalProcessEvent(self, func, params)
                end
                return
            end
            
            local funcName = tostring(func:GetFullName()) or ""
            
            if string.find(funcName, "RPC_ClientCoronaLab") then
                return
            end
            
            if _G.OriginalProcessEvent then
                return _G.OriginalProcessEvent(self, func, params)
            end
        end
        
        _G.ProcessEventHooked = true
    end)
    return false
end

-- ==================== 社交大厅槽位解锁与装备 ====================
pcall(function()
    local Logic_SocialLobbyModule = ModuleManager and ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)

    if not Logic_SocialLobbyModule then
        print("[SocialLobbySlots] Logic_SocialLobbyModule not found")
        return
    end

    local function isSelfUid(uid)
        if not uid or not DataMgr or not DataMgr.roleData then return false end
        return tonumber(uid) == tonumber(DataMgr.roleData.uid)
    end

    -- ==================== Slot Types ====================
    local SLOT_AVATAR    = 1
    local SLOT_VEHICLE   = 2
    local SLOT_WEAPON    = 3
    local SLOT_PET       = 4
    local SLOT_BGWALL    = 100

    -- ==================== 槽位数量 ====================
    local WEAPON_SLOTS_MAX   = 8
    local VEHICLE_SLOTS_MAX  = 6
    local AVATAR_SLOTS_MAX   = 6
    local PET_SLOTS_MAX      = 4
    local ALL_SLOT_TYPES = { SLOT_AVATAR, SLOT_VEHICLE, SLOT_WEAPON, SLOT_PET }

    -- ==================== 物品列表 ====================
    local WEAPON_SLOTS = {
        [1] = 1101101007,
        [2] = 1101004246,
        [3] = 1101004218,
        [4] = 1101004226,
        [5] = 1101003227,
        [6] = 1101005098,
        [7] = 1101006085,
        [8] = 1101008146,
    }

    local VEHICLE_SLOTS = {
        [1] = 1961062,
        [2] = 1961152,
        [3] = 1961153,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    }

    local AVATAR_SLOTS = {
        [1] = 1407895,
        [2] = 1406469,
        [3] = 1406971,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    }

    local PET_SLOTS = {
        [1] = 50024,
        [2] = 0,
        [3] = 0,
        [4] = 0,
    }

    -- ==================== 解锁所有槽位 ====================
    function ForceUnlockAllSlots()
        local uid = DataMgr and DataMgr.roleData and DataMgr.roleData.uid
        if not uid then return end
        uid = tonumber(uid)

        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return end

        local nCurTime = os.time and os.time() or 9999999999

        if not tSocialData.mixed_hall_slot_unlock_info then
            tSocialData.mixed_hall_slot_unlock_info = {}
        end
        for _, slotType in ipairs(ALL_SLOT_TYPES) do
            if not tSocialData.mixed_hall_slot_unlock_info[slotType] then
                tSocialData.mixed_hall_slot_unlock_info[slotType] = {}
            end
        end

        for i = 1, WEAPON_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_WEAPON][i] = nCurTime
        end
        for i = 1, VEHICLE_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_VEHICLE][i] = nCurTime
        end
        for i = 1, AVATAR_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_AVATAR][i] = nCurTime
        end
        for i = 1, PET_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_PET][i] = nCurTime
        end

        if not tSocialData.mixed_data then
            tSocialData.mixed_data = {}
        end
        for _, slotType in ipairs(ALL_SLOT_TYPES) do
            if not tSocialData.mixed_data[slotType] then
                tSocialData.mixed_data[slotType] = {}
            end
        end
    end

    -- ==================== 发送更新事件 ====================
    local function FireSlotUpdateEvents(slotType, slotIndex)
        pcall(function()
            if EventSystem and EVENTTYPE_LOBBY_SOCIAL then
                if EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
                    EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE, slotType, slotIndex)
                end
                if EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
                    EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA)
                end
            end
        end)
    end

    local function FireShowDataEvent()
        pcall(function()
            if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
                EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA)
            end
        end)
    end

    -- ==================== 装备武器 ====================
    function EquipWeaponToSlot(nWeaponItemId, nSlotIndex)
        if not isSelfUid(DataMgr and DataMgr.roleData and DataMgr.roleData.uid) then
            print("[Slots] Not self UID!")
            return false
        end
        nSlotIndex = tonumber(nSlotIndex) or 1
        nWeaponItemId = tonumber(nWeaponItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > WEAPON_SLOTS_MAX then
            print("[Slots] Invalid weapon slot: " .. tostring(nSlotIndex))
            return false
        end
        if nWeaponItemId <= 0 then
            print("[Slots] Invalid weapon ID: " .. tostring(nWeaponItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_WEAPON] then tSocialData.mixed_data[SLOT_WEAPON] = {} end

        local nFakeInstId = nWeaponItemId * 1000 + nSlotIndex
        tSocialData.mixed_data[SLOT_WEAPON][nSlotIndex] = {
            resid = nWeaponItemId,
            instid = nFakeInstId,
            weapon_id = 0
        }
        WEAPON_SLOTS[nSlotIndex] = nWeaponItemId

        FireSlotUpdateEvents(SLOT_WEAPON, nSlotIndex)
        print("[Slots] Weapon " .. nWeaponItemId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== 装备载具 ====================
    function EquipVehicleToSlot(nVehicleItemId, nSlotIndex)
        nSlotIndex = tonumber(nSlotIndex) or 1
        nVehicleItemId = tonumber(nVehicleItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > VEHICLE_SLOTS_MAX then
            print("[Slots] Invalid vehicle slot: " .. tostring(nSlotIndex))
            return false
        end
        if nVehicleItemId <= 0 then
            print("[Slots] Invalid vehicle ID: " .. tostring(nVehicleItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_VEHICLE] then tSocialData.mixed_data[SLOT_VEHICLE] = {} end

        local nFakeInstId = nVehicleItemId * 1000 + nSlotIndex
        tSocialData.mixed_data[SLOT_VEHICLE][nSlotIndex] = {
            resid = nVehicleItemId,
            instid = nFakeInstId
        }
        VEHICLE_SLOTS[nSlotIndex] = nVehicleItemId

        FireSlotUpdateEvents(SLOT_VEHICLE, nSlotIndex)
        print("[Slots] Vehicle " .. nVehicleItemId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== 装备服装 ====================
    function EquipAvatarToSlot(nItemId, nSlotIndex)
        nSlotIndex = tonumber(nSlotIndex) or 1
        nItemId = tonumber(nItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > AVATAR_SLOTS_MAX then
            print("[Slots] Invalid avatar slot: " .. tostring(nSlotIndex))
            return false
        end
        if nItemId <= 0 then
            print("[Slots] Invalid avatar ID: " .. tostring(nItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_AVATAR] then tSocialData.mixed_data[SLOT_AVATAR] = {} end

        local nAvatarSlotType = 3
        pcall(function()
            local uItemCfg = CDataTable.GetTableData("Item", nItemId)
            if uItemCfg then
                local Logic_AvatarWardrobeDataTools = require("client.slua.logic.lobby.Left.SocialLobby.Logic_AvatarWardrobeDataTools")
                if Logic_AvatarWardrobeDataTools and Logic_AvatarWardrobeDataTools.GetAvatarSlotType then
                    nAvatarSlotType = Logic_AvatarWardrobeDataTools.GetAvatarSlotType(uItemCfg.ItemSubType) or 3
                end
            end
        end)

        local nFakeInstId = nItemId * 1000 + nSlotIndex
        local existingSlotData = tSocialData.mixed_data[SLOT_AVATAR][nSlotIndex] or {
            gender = 1,
            pose_type = 0,
            item_info = {}
        }
        if not existingSlotData.item_info then
            existingSlotData.item_info = {}
        end
        existingSlotData.item_info[nAvatarSlotType] = {
            resid = nItemId,
            instid = nFakeInstId,
            origin_resid = 0
        }
        existingSlotData.bIsEditData = true
        tSocialData.mixed_data[SLOT_AVATAR][nSlotIndex] = existingSlotData
        AVATAR_SLOTS[nSlotIndex] = nItemId

        FireSlotUpdateEvents(SLOT_AVATAR, nSlotIndex)
        print("[Slots] Avatar " .. nItemId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== 装备宠物 ====================
    function EquipPetToSlot(nPetId, nSlotIndex)
        nSlotIndex = tonumber(nSlotIndex) or 1
        nPetId = tonumber(nPetId) or 0
        if nSlotIndex < 1 or nSlotIndex > PET_SLOTS_MAX then
            print("[Slots] Invalid pet slot: " .. tostring(nSlotIndex))
            return false
        end
        if nPetId <= 0 then
            print("[Slots] Invalid pet ID: " .. tostring(nPetId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_PET] then tSocialData.mixed_data[SLOT_PET] = {} end

        tSocialData.mixed_data[SLOT_PET][nSlotIndex] = {
            pet_id = nPetId,
            pet_dress = {}
        }
        PET_SLOTS[nSlotIndex] = nPetId

        FireSlotUpdateEvents(SLOT_PET, nSlotIndex)
        print("[Slots] Pet " .. nPetId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== 移除槽位物品 ====================
    function UnequipSlot(nSlotType, nSlotIndex)
        nSlotType = tonumber(nSlotType) or 1
        nSlotIndex = tonumber(nSlotIndex) or 1
        local uid = tonumber(DataMgr.roleData.uid)

        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData or not tSocialData.mixed_data or not tSocialData.mixed_data[nSlotType] then
            return false
        end

        tSocialData.mixed_data[nSlotType][nSlotIndex] = nil
        FireSlotUpdateEvents(nSlotType, nSlotIndex)
        print("[Slots] Removed type=" .. nSlotType .. " index=" .. nSlotIndex)
        return true
    end

    -- ==================== 批量装备所有物品 ====================
    function EquipAllFromLists()
        local count = 0
        for i, v in pairs(WEAPON_SLOTS) do
            if v and v > 0 then EquipWeaponToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(VEHICLE_SLOTS) do
            if v and v > 0 then EquipVehicleToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(AVATAR_SLOTS) do
            if v and v > 0 then EquipAvatarToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(PET_SLOTS) do
            if v and v > 0 then EquipPetToSlot(v, i); count = count + 1 end
        end
        print("[Slots] Equipped " .. count .. " items total")
        return count
    end

    -- ==================== Hook GetSlotTypeMaxCount ====================
    local orig_GetSlotTypeMaxCount = Logic_SocialLobbyModule.GetSlotTypeMaxCount
    Logic_SocialLobbyModule.GetSlotTypeMaxCount = function(self, nUId, nSlotType, bIsGetShowCount)
        if isSelfUid(nUId) then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetSlotTypeMaxCount(self, nUId, nSlotType, bIsGetShowCount)
    end

    -- ==================== Hook GetSlotIsUnlockBySlotTypeAndIndex ====================
    local orig_GetSlotIsUnlock = Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex
    Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex = function(self, nUId, nSlotType, nSlotIndex)
        if nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            return true
        end
        return orig_GetSlotIsUnlock(self, nUId, nSlotType, nSlotIndex)
    end

    -- ==================== Hook GetSlotIsUnlockedByCollectHallLevel ====================
    local orig_GetSlotIsUnlockedByLevel = Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel
    Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel = function(self, nUId, nSlotType, nSlotIndex)
        if nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            return true
        end
        return orig_GetSlotIsUnlockedByLevel(self, nUId, nSlotType, nSlotIndex)
    end

    -- ==================== Hook GetSlotTypeUCUnlockMaxCount ====================
    local orig_GetUCUnlockMax = Logic_SocialLobbyModule.GetSlotTypeUCUnlockMaxCount
    Logic_SocialLobbyModule.GetSlotTypeUCUnlockMaxCount = function(self, nSlotType)
        if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
        if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
        if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
        if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        return orig_GetUCUnlockMax(self, nSlotType)
    end

    -- ==================== Hook GetSlotTypeAllUnlockData ====================
    local orig_GetAllUnlockData = Logic_SocialLobbyModule.GetSlotTypeAllUnlockData
    Logic_SocialLobbyModule.GetSlotTypeAllUnlockData = function(self, nUId, nSlotType)
        if nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            ForceUnlockAllSlots()
            local tSocialData = Logic_SocialLobbyModule:GetSocialData(nUId)
            return tSocialData and tSocialData.mixed_hall_slot_unlock_info and tSocialData.mixed_hall_slot_unlock_info[nSlotType] or {}
        end
        return orig_GetAllUnlockData(self, nUId, nSlotType)
    end

    -- ==================== Hook CheckSlotTypeIsUCUnlock ====================
    local orig_CheckUCUnlock = Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock
    Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock = function(self, nSlotType, nSlotIndex)
        if nSlotType == SLOT_WEAPON or nSlotType == SLOT_VEHICLE or nSlotType == SLOT_AVATAR or nSlotType == SLOT_PET then
            return false
        end
        return orig_CheckUCUnlock(self, nSlotType, nSlotIndex)
    end

    -- ==================== Hook GetSlotUnlockCountByCollectHallLevel ====================
    local orig_GetUnlockCountByLevel = Logic_SocialLobbyModule.GetSlotUnlockCountByCollectHallLevel
    Logic_SocialLobbyModule.GetSlotUnlockCountByCollectHallLevel = function(self, nUId, nSlotType)
        if isSelfUid(nUId) then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetUnlockCountByLevel(self, nUId, nSlotType)
    end

    -- ==================== Hook GetWeaponSlotIsShowBySlotIndex ====================
    local orig_GetWeaponSlotShow = Logic_SocialLobbyModule.GetWeaponSlotIsShowBySlotIndex
    Logic_SocialLobbyModule.GetWeaponSlotIsShowBySlotIndex = function(self, nSlotIndex)
        if isSelfUid(self._sCurUId) then return true end
        return orig_GetWeaponSlotShow(self, nSlotIndex)
    end

    -- ==================== 初始化武器槽位索引 ====================
    Logic_SocialLobbyModule._tWeaponSlotIndex = { [1] = {}, [2] = {} }
    for page = 1, 2 do
        for i = 1, WEAPON_SLOTS_MAX do
            Logic_SocialLobbyModule._tWeaponSlotIndex[page][i] = true
        end
    end

    -- ==================== Hook RefreshUIStateShow ====================
    pcall(function()
        local SlotBase = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase")
        if SlotBase and SlotBase.RefreshUIStateShow and not SlotBase._all_slots_orig then
            SlotBase._all_slots_orig = SlotBase.RefreshUIStateShow
            SlotBase.RefreshUIStateShow = function(self)
                if self._nSlotType ~= SLOT_BGWALL and self._bIsSelf then
                    if self.CanvasPanel_Lock then
                        self:SetWidgetVisible(self.CanvasPanel_Lock, false)
                    end
                    local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
                    if Logic_SocialLobbyEditMgrModule then
                        local bIsEditing = Logic_SocialLobbyEditMgrModule:GetIsEditing()
                        if bIsEditing and self.CanvasPanel_Empty then
                            self:SetWidgetVisible(self.CanvasPanel_Empty, true, false)
                        end
                    end
                    self:_RequestRedraw()
                    return
                end
                return SlotBase._all_slots_orig(self)
            end
        end
    end)

    -- ==================== Hook OnSlotButtonClick ====================
    pcall(function()
        local SlotBase = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase")
        if SlotBase and SlotBase.OnSlotButtonClick and not SlotBase._all_slots_click_orig then
            SlotBase._all_slots_click_orig = SlotBase.OnSlotButtonClick
            SlotBase.OnSlotButtonClick = function(self)
                if self._nSlotType ~= SLOT_BGWALL and self._bIsSelf then
                    local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
                    if Logic_SocialLobbyEditMgrModule then
                        Logic_SocialLobbyEditMgrModule:EnterEditState(self._nShowUId, self._nSlotType, self._nSlotIndex)
                        return
                    end
                end
                return SlotBase._all_slots_click_orig(self)
            end
        end
    end)

    -- ==================== 执行解锁和装备 ====================
    pcall(function()
        ForceUnlockAllSlots()
        EquipAllFromLists()
    end)

    -- 延迟执行确保模块加载完成
    pcall(function()
        local tt = require("common.time_ticker")
        if tt and tt.AddTimerOnce then
            tt.AddTimerOnce(1, function()
                pcall(function()
                    ForceUnlockAllSlots()
                    EquipAllFromLists()
                    FireShowDataEvent()
                end)
            end)
            tt.AddTimerOnce(1, function()
                pcall(function()
                    ForceUnlockAllSlots()
                    EquipAllFromLists()
                    FireShowDataEvent()
                end)
            end)
        end
    end)
end)









-- ==================== 排名伪造模块 ====================
-- 配置（修改这里的数值来改变显示效果）
_G.RankSpoof_Enabled = true   -- 开关：true=开启, false=关闭
_G.RankSpoof_Rank = 1         -- 排名（1=第1名）
_G.RankSpoof_Score = 130000   -- 总积分
_G.RankSpoof_Content1 = "120" -- 胜场/杀敌数1
_G.RankSpoof_Content2 = "80"  -- 胜场/杀敌数2
_G.RankSpoof_Content3 = "45"  -- 胜场/杀敌数3
_G.RankSpoof_Segment = 801    -- 段位（801=征服者）
_G.RankSpoof_Stars = 80       -- 征服者星星数

-- 核心代码（直接复制粘贴，不要修改）
do
    local M = _G.ClientRankSpoof or {}
    _G.ClientRankSpoof = M
    local SIG = "v7|" .. tostring(_G.RankSpoof_Enabled) .. "|" .. tostring(_G.RankSpoof_Rank) .. "|" .. tostring(_G.RankSpoof_Score) .. "|" .. tostring(_G.RankSpoof_Content1) .. "|" .. tostring(_G.RankSpoof_Content2) .. "|" .. tostring(_G.RankSpoof_Content3) .. "|" .. tostring(_G.RankSpoof_Segment) .. "|" .. tostring(_G.RankSpoof_Stars)
    if M._installed and M._sig == SIG then return end
    if M._sig and M._sig ~= SIG then M._hooks = {} end
    
    M.cfg = {
        enabled = _G.RankSpoof_Enabled,
        rankNo = _G.RankSpoof_Rank,
        score = _G.RankSpoof_Score,
        content1 = tostring(_G.RankSpoof_Content1),
        content2 = tostring(_G.RankSpoof_Content2),
        content3 = tostring(_G.RankSpoof_Content3),
        segment = _G.RankSpoof_Segment,
        stars = _G.RankSpoof_Stars,
    }
    M._installed = true
    M._sig = SIG
    M._hooks = M._hooks or {}
    
    local MODES = {"solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad"}
    local COALESCE_SEC = 0.5
    
    local function myUid()
        if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
            return tostring(DataMgr.roleData.uid)
        end
        return nil
    end
    
    local function isSelf(uid)
        local u = myUid()
        return M.cfg.enabled and u and uid and tostring(uid) == u
    end
    
    local function getRankDataMgr()
        local ok, m = pcall(require, "client.slua.logic.rank.rank_data_mgr")
        return ok and m or nil
    end
    
    local function getZoneId()
        local RankDataMgr = getRankDataMgr()
        return RankDataMgr and RankDataMgr.GetRankSelectZoneId() or 1
    end
    
    local function getCurrentModeId()
        local RankDataMgr = getRankDataMgr()
        if not RankDataMgr then return 3 end
        local RankConfig = require("client.slua.logic.rank.rank_config")
        local m = RankDataMgr.GetRankSelectMemberType()
        local MemberEnum = RankConfig.MemberEnum
        if RankDataMgr.IsFpp() then
            if m == MemberEnum.single then return 4 end
            if m == MemberEnum.double then return 5 end
            return 6
        end
        if m == MemberEnum.single then return 1 end
        if m == MemberEnum.double then return 2 end
        return 3
    end
    
    local function conquerorRating(stars)
        stars = tonumber(stars) or 1
        if stars < 1 then stars = 1 end
        return 4200 + (stars - 1) * 100
    end
    
    local function patchZoneRankData(zData, score, rating, seg)
        if type(zData) ~= "table" then return end
        zData.total_rank_rating = score
        zData.fpp_total_rank_rating = score
        for _, mode in ipairs(MODES) do
            zData[mode] = zData[mode] or {}
            zData[mode].rank_rating = rating
            zData[mode].level = seg
        end
    end
    
    local function patchSegmentTable(segTable, zoneId, seg)
        if type(segTable) ~= "table" then return end
        segTable[zoneId] = segTable[zoneId] or {}
        for i = 1, 6 do
            segTable[zoneId][i] = seg
        end
    end
    
    local function patchProfileInPlace(profile, zoneId)
        if not profile or not M.cfg.enabled then return end
        zoneId = zoneId or getZoneId()
        local seg = M.cfg.segment
        local rating = conquerorRating(M.cfg.stars)
        local score = math.floor(M.cfg.score + 0.5)
        profile.rankdata = profile.rankdata or {}
        profile.rankdata[zoneId] = profile.rankdata[zoneId] or {}
        patchZoneRankData(profile.rankdata[zoneId], score, rating, seg)
        profile.segment_info = profile.segment_info or {}
        patchSegmentTable(profile.segment_info, zoneId, seg)
    end
    
    local function patchDataMgr(zoneId)
        if not M.cfg.enabled or not DataMgr or not DataMgr.roleData then return end
        zoneId = zoneId or getZoneId()
        local seg = M.cfg.segment
        local rating = conquerorRating(M.cfg.stars)
        local score = math.floor(M.cfg.score + 0.5)
        DataMgr.roleData.rankdata = DataMgr.roleData.rankdata or {}
        DataMgr.roleData.rankdata[zoneId] = DataMgr.roleData.rankdata[zoneId] or {}
        patchZoneRankData(DataMgr.roleData.rankdata[zoneId], score, rating, seg)
        DataMgr.roleData.allzoneSegment = DataMgr.roleData.allzoneSegment or {}
        patchSegmentTable(DataMgr.roleData.allzoneSegment, zoneId, seg)
        DataMgr.roleData.segment = DataMgr.roleData.segment or {}
        DataMgr.roleData.segment.solo = seg
        DataMgr.roleData.segment.double = seg
        DataMgr.roleData.segment.team = seg
        DataMgr.roleData.segment.fpp_solo = seg
        DataMgr.roleData.segment.fpp_double = seg
        DataMgr.roleData.segment.fpp_team = seg
    end
    
    local function touchItem(item)
        if not M.cfg.enabled or not item then return end
        local c = M.cfg
        local zoneId = getZoneId()
        local modeId = getCurrentModeId()
        local rating = conquerorRating(c.stars)
        local score = math.floor(c.score + 0.5)
        item.no = c.rankNo
        item.score = score
        item.content1 = tostring(c.content1)
        item.content2 = tostring(c.content2)
        item.content3 = tostring(c.content3)
        item.segment = c.segment
        item.segmentTitleId = 0
        item.segmentModeId = modeId
        item.segmentZoneId = zoneId
        item.segment_info = item.segment_info or {}
        for i = 1, 6 do item.segment_info[i] = c.segment end
        item.all_segment_info = item.all_segment_info or {}
        patchSegmentTable(item.all_segment_info, zoneId, c.segment)
        item.rankdata = item.rankdata or {}
        patchZoneRankData(item.rankdata, score, rating, c.segment)
    end
    
    local function applyList()
        if not M.cfg.enabled then return end
        local uid = myUid()
        if not uid then return end
        local rank_data = require("client.slua.logic.rank.rank_data")
        local list = rank_data.GetRankDataList()
        if type(list) ~= "table" then return end
        local selfItem = rank_data.GetSelfRankData()
        if not selfItem then return end
        touchItem(selfItem)
        for i = #list, 1, -1 do
            if list[i] and tostring(list[i].uid) == uid then
                table.remove(list, i)
            end
        end
        table.insert(list, math.min(M.cfg.rankNo, #list + 1), selfItem)
        pcall(rank_data.UpdateUidRankMap)
        local rdm = getRankDataMgr()
        if rdm then rdm.SetSelfBelow1wDisplay(tostring(M.cfg.rankNo)) end
    end
    
    local function scheduleSilentFix()
        if M._inSilentFix then return end
        M._inSilentFix = true
        pcall(function()
            patchDataMgr()
            local rank_data = require("client.slua.logic.rank.rank_data")
            local selfItem = rank_data.GetSelfRankData()
            if selfItem then touchItem(selfItem) end
            applyList()
        end)
        M._inSilentFix = false
    end
    
    function M.refreshUIOnce()
        scheduleSilentFix()
        pcall(function()
            local RankDataMgr = getRankDataMgr()
            if RankDataMgr then
                local t = RankDataMgr.GetRankSelectType()
                if EventSystem then
                    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_LIST, t)
                    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_SELF, t)
                end
            end
        end)
    end
    
    -- 安装Hook
    local function installHooks()
        local ok, rank_data = pcall(require, "client.slua.logic.rank.rank_data")
        if not ok or not rank_data then return false end
        
        local function hookMod(mod, name, wrapper)
            if not mod or not mod[name] or M._hooks[name] then return false end
            M._hooks[name] = mod[name]
            mod[name] = wrapper
            return true
        end
        
        hookMod(rank_data, "SortTotalRankList", function(...)
            local r = M._hooks.SortTotalRankList(...)
            if M.cfg.enabled then applyList() end
            return r
        end)
        
        hookMod(rank_data, "SetSelfRankData", function(raw_self, convertFunction)
            M._hooks.SetSelfRankData(raw_self, convertFunction)
            if M.cfg.enabled and raw_self and isSelf(raw_self.uid) then
                touchItem(require("client.slua.logic.rank.rank_data").GetSelfRankData())
            end
        end)
        
        return true
    end
    
    if not M._hooks.SortTotalRankList then
        pcall(installHooks)
    end
    
    -- 延迟刷新
    pcall(function()
        local tt = require("common.time_ticker")
        tt.AddTimer(0.5, function()
            if M.cfg.enabled then M.refreshUIOnce() end
            return true
        end)
    end)
    
    -- 添加到主定时器循环
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(3, function()
            if M.cfg.enabled then pcall(M.refreshUIOnce) end
        end, -1, 1)
    end
end













-- ==================== 移动拖尾特效（三拖尾支持） ====================
-- 支持浮光金叶拖尾(4531002)、星绘幻紫拖尾(4531001)、炫酷涂鸦足迹(4541001)

-- 从配置文件读取开关状态
local function IsTrailEnabled()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("TRAIL_ENABLE", 0)  -- 默认 0=关闭
    end
    return configValue == 1
end

-- 从配置文件读取拖尾类型
local function GetTrailItemId()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("TRAIL_TYPE", nil)
    end
    if configValue ~= nil and configValue ~= 0 then
        return tonumber(configValue)
    end
    return 4531002  -- 默认浮光金叶
end

-- 全局模块
_G.GoldenLeavesTrail = _G.GoldenLeavesTrail or {}
_G.GoldenLeavesTrail.Enabled = IsTrailEnabled()
_G.GoldenLeavesTrail.TRAIL_ITEM_ID = GetTrailItemId()

-- 拖尾名称映射（更新为三个）
local TRAIL_NAMES = {
    [4531001] = "星绘幻紫拖尾",
    [4531002] = "浮光金叶拖尾",
    [4541001] = "炫酷涂鸦足迹",
}

-- 所有支持的拖尾ID列表
local SUPPORTED_TRAILS = {4531001, 4531002, 4541001}

-- 预下载所有拖尾资源
local function PreloadTrails()
    pcall(function()
        local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local PufferConst = require("client.slua.logic.download.puffer_const")
        if PufferManager and PufferManager.Download then
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, SUPPORTED_TRAILS)
        end
    end)
end

local TrailConfig = {
    DELAY_SEC = 0.5,
    TICKER_SEC = 2.0,   -- ★ 功耗：0.5 → 2.0 秒
    USE_TICKER = true,
    FORCE_SELF_VISIBLE = true,
}

-- ========== 修复：跟踪对局状态，确保每局重新应用 ==========
local _isInMatch = false
local _wasInMatch = false

local function GetCharacter()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD then
        local char = GD.GetPlayerCharacter()
        if char and slua.isValid(char) then
            return char
        end
    end
    if slua_GameFrontendHUD then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if pc and pc.GetPlayerCharacterSafety then
            local char = pc:GetPlayerCharacterSafety()
            if char and slua.isValid(char) then
                return char
            end
        end
    end
    return nil
end

local function GetAvatarComponent(char)
    char = char or GetCharacter()
    if not char or not slua.isValid(char) then
        return nil
    end
    if char.getAvatarComponent2 then
        local comp = char:getAvatarComponent2()
        if comp and slua.isValid(comp) then
            return comp
        end
    end
    return nil
end

local function IsInFighting()
    local ok, r = pcall(function()
        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
    end)
    return ok and r == true
end

local function IsInLobby()
    local ok, r = pcall(function()
        return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()
    end)
    return ok and r == true
end

-- 检查是否在比赛对局中
local function IsInMatch()
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    if IsInLobby() then
        return false
    end
    local ok, isFighting = pcall(function()
        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
    end)
    if ok then
        return isFighting == true
    end
    local char = GetCharacter()
    return char and slua.isValid(char)
end

local function ApplyTrailToComponent(comp)
    if not comp or not slua.isValid(comp) then
        return false
    end
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    
    local trailId = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
    comp.MoveEffectItem = trailId
    if comp.AdditionEffectMgr then
        comp.AdditionEffectMgr:SetMoveEffectItem(trailId)
    elseif comp.OnRep_MoveEffectItem then
        comp:OnRep_MoveEffectItem(0)
    end
    return true
end

local function ApplyTrailEffect(char)
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    if not IsInMatch() then
        return false
    end
    
    char = char or GetCharacter()
    if char and slua.isValid(char) then
        local comp = GetAvatarComponent(char)
        if ApplyTrailToComponent(comp) then
            return true
        end
    end
    return false
end

-- 停止拖尾
function _G.GoldenLeavesTrail.Stop()
    pcall(function()
        local char = GetCharacter()
        if char and slua.isValid(char) then
            local comp = GetAvatarComponent(char)
            if comp and slua.isValid(comp) then
                comp.MoveEffectItem = 0
                if comp.AdditionEffectMgr then
                    comp.AdditionEffectMgr:SetMoveEffectItem(0)
                end
            end
        end
    end)
end

-- 切换拖尾类型（更新为支持三个）
function _G.GoldenLeavesTrail.SetType(trailId)
    trailId = tonumber(trailId) or 4531002
    -- 检查是否支持的拖尾ID
    local supported = false
    for _, id in ipairs(SUPPORTED_TRAILS) do
        if id == trailId then
            supported = true
            break
        end
    end
    if not supported then
        trailId = 4531002
    end
    _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Set then
        _G.DazhiMH_Config.Set("TRAIL_TYPE", trailId)
    end
    if _G.GoldenLeavesTrail.Enabled then
        pcall(_G.GoldenLeavesTrail.Apply)
    end
    local name = TRAIL_NAMES[trailId] or tostring(trailId)
    print("[Trail] 切换到: " .. name)
end

-- Hook PufferManager（支持三个拖尾）
local function HookPufferManager()
    pcall(function()
        local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local PufferConst = require("client.slua.logic.download.puffer_const")
        if not PufferManager or not PufferManager.GetState or PufferManager._GLT_Patched then
            return
        end
        PufferManager._GLT_Patched = true
        local origGetState = PufferManager.GetState
        PufferManager.GetState = function(downloadType, keyList, ...)
            if keyList then
                for _, key in pairs(keyList) do
                    local id = tonumber(key)
                    for _, supported in ipairs(SUPPORTED_TRAILS) do
                        if id == supported then
                            return PufferConst.ENUM_DownloadState.Done
                        end
                    end
                end
            end
            return origGetState(downloadType, keyList, ...)
        end
        if _G.download_item then
            local origDownload = _G.download_item
            _G.download_item = function(id)
                local tid = tonumber(id)
                for _, supported in ipairs(SUPPORTED_TRAILS) do
                    if tid == supported then return end
                end
                return origDownload(id)
            end
        end
    end)
end

-- Hook 物品有效性检查（支持三个拖尾）
local function HookItemValid()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.CheckItemValid or CAC._GLT_CheckItemValid then
            return
        end
        CAC._GLT_CheckItemValid = true
        local orig = CAC.CheckItemValid
        CAC.CheckItemValid = function(self, resID)
            local rid = tonumber(resID)
            for _, supported in ipairs(SUPPORTED_TRAILS) do
                if rid == supported then
                    return true
                end
            end
            return orig(self, resID)
        end
    end)
end

-- Hook 初始化装备
local function HookInitDepot()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.InitDepotCommonPutOn or CAC._GLT_InitDepot then
            return
        end
        CAC._GLT_InitDepot = true
        local orig = CAC.InitDepotCommonPutOn
        CAC.InitDepotCommonPutOn = function(self)
            orig(self)
            if _G.GoldenLeavesTrail.Enabled and IsInMatch() and self.IsSelf and self:IsSelf() then
                self.MoveEffectItem = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
                if Client and self.AdditionEffectMgr then
                    self.AdditionEffectMgr:SetMoveEffectItem(_G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002)
                end
            end
        end
    end)
end

-- Hook 特效可见性
local function HookEffectVisibility()
    if not TrailConfig.FORCE_SELF_VISIBLE then
        return
    end
    pcall(function()
        local ECPB = require("GameLua.Mod.Library.GamePlay.Avatar.Component.EffectProc.EffectContionProcessorBase")
        if not ECPB or not ECPB.AdditionEffectCheck or ECPB._GLT_AdditionCheck then
            return
        end
        ECPB._GLT_AdditionCheck = true
        local orig = ECPB.AdditionEffectCheck
        ECPB.AdditionEffectCheck = function(self, character)
            if _G.GoldenLeavesTrail.Enabled then
                local mgr = self.OwnerEffectMgr
                local comp = mgr and mgr.GetOwnerAvatarComponent and mgr:GetOwnerAvatarComponent()
                if slua.isValid(comp) and comp.IsSelf and comp:IsSelf() then
                    if IsInMatch() then
                        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                        local localChar = GameplayData.GetLocalCharacter()
                        if slua.isValid(localChar) and localChar.bIsGunADS then
                            return false
                        end
                        return true
                    end
                    return false
                end
            end
            return orig(self, character)
        end
    end)
end

-- Hook 模型加载完成时应用特效
local function HookMeshLoaded()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.OnAvatarAllMeshLoadedLua or CAC._GLT_MeshLoaded then
            return
        end
        CAC._GLT_MeshLoaded = true
        local orig = CAC.OnAvatarAllMeshLoadedLua
        CAC.OnAvatarAllMeshLoadedLua = function(self)
            orig(self)
            pcall(function()
                if self.IsLobbyActor and self:IsLobbyActor() then
                    return
                end
                if self.IsSelf and not self:IsSelf() then
                    return
                end
                if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                    self.MoveEffectItem = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
                    if self.AdditionEffectMgr then
                        self.AdditionEffectMgr:SetMoveEffectItem(_G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002)
                    end
                end
            end)
        end
    end)
end

-- 安装所有Hook
local function InstallAllHooks()
    if _G._GoldenLeavesTrailHooked then
        return
    end
    _G._GoldenLeavesTrailHooked = true
    HookPufferManager()
    HookItemValid()
    HookInitDepot()
    HookEffectVisibility()
    HookMeshLoaded()
end

-- 应用
function _G.GoldenLeavesTrail.Apply()
    InstallAllHooks()
    if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
        return ApplyTrailEffect()
    end
    return false
end

-- ========== 修复：每局重新应用 ==========
local function EnsureTrailApplied()
    local inMatch = IsInMatch()
    
    -- 检测到进入对局
    if inMatch and not _wasInMatch then
        print("[Trail] 检测到进入对局，重新应用拖尾")
        _G.GoldenLeavesTrail.Apply()
    end
    
    -- 检测到离开对局
    if not inMatch and _wasInMatch then
        print("[Trail] 离开对局，停止拖尾")
        _G.GoldenLeavesTrail.Stop()
    end
    
    _wasInMatch = inMatch
end

-- 启动定时器（修复：更频繁检查对局状态）
local function StartTicker()
    if not TrailConfig.USE_TICKER then
        return
    end
    pcall(function()
        if _G.Mytimer_ticker then
            -- 添加对局状态检测定时器（0.5秒检测一次）
            _G.Mytimer_ticker.AddTimerLoop(TrailConfig.TICKER_SEC, function()
                pcall(EnsureTrailApplied)
                
                -- 如果在对局中且开关开启，持续应用
                if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                    pcall(ApplyTrailEffect)
                elseif not _G.GoldenLeavesTrail.Enabled then
                    pcall(_G.GoldenLeavesTrail.Stop)
                end
            end, -1, 1)
        end
    end)
end

-- 启动
local function Start()
    InstallAllHooks()
    PreloadTrails()
    local char = GetCharacter()
    if char and char.AddGameTimer then
        char:AddGameTimer(TrailConfig.DELAY_SEC, false, function()
            if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                _G.GoldenLeavesTrail.Apply()
            end
        end)
    else
        if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
            _G.GoldenLeavesTrail.Apply()
        end
    end
    StartTicker()
end

if not _G._GoldenLeavesTrailLoaded then
    _G._GoldenLeavesTrailLoaded = true
    Start()
end

-- 导出
_G.GoldenLeavesTrail.IsInMatch = IsInMatch
_G.GoldenLeavesTrail.ApplyToChar = ApplyTrailEffect
_G.GoldenLeavesTrail.GetTrailName = function(id)
    return TRAIL_NAMES[id] or "未知拖尾"
end

print("[Trail] 已加载，当前拖尾: " .. (TRAIL_NAMES[_G.GoldenLeavesTrail.TRAIL_ITEM_ID] or "未知") .. " (ID: " .. tostring(_G.GoldenLeavesTrail.TRAIL_ITEM_ID) .. ")")


-- ==================== 手雷爆炸特效皮肤模块（v27 静音极速版） ====================
do
local M = {}
_G.GrenadeFX = M
local GRENADE_SKIN_ID = 612004238

-- ★ 爆炸特效大小：从 _G.GrenadeFX8_Scale 读（默认 1.0，范围 0.5~5.0）
-- 修改方式：GrenadeFX.SetScale(2.0)  或 wumingking.h 里写 GRENADE_FX_SCALE=200
if not _G.GrenadeFX8_Scale then
    local _cfgVal = 100
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        _cfgVal = tonumber(_G.DazhiMH_Config.Get("GRENADE_FX_SCALE", 100)) or 100
    end
    if _cfgVal < 50  then _cfgVal = 50  end
    if _cfgVal > 500 then _cfgVal = 500 end
    _G.GrenadeFX8_Scale = _cfgVal / 100.0
end

local function getGrenadeScale()
    local s = tonumber(_G.GrenadeFX8_Scale) or 1.0
    if s < 0.5 then s = 0.5 end
    if s > 5.0 then s = 5.0 end
    return s
end

local FORCE_WEAPON_ID = nil
local SOURCE_FX_ID = 1101006100
local FALLBACK_FX = "/Game/Arts_Effect/ParticleSystems/Grenade/P_Grenade_Fire_Explode_01_Int.P_Grenade_Fire_Explode_01_Int"

-- ★ 破片手雷 ID
local FRAG_GRENADE_ID = 602004

local UGameplayStatics = import("GameplayStatics")
local applied = false
local fxHooked = false
local preloaded = false
local preloadedForId = nil
local cachedParticle = nil
local cachedSeqPath = nil
local fragClass = nil

local resourceChecked = false
local _lastHandID = nil

-- 极简静音 log
local function log(msg) end

local function GetPC()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok or not GD then return nil end
    local PC = GD.GetPlayerController()
    if not slua.isValid(PC) then return nil end
    return PC
end

local function GetActorItemID(actor)
    local id = nil
    pcall(function()
        if actor.ItemDefineID then
            id = actor.ItemDefineID.TypeSpecificID
        end
    end)
    if not id or id == 0 then
        pcall(function()
            id = actor.GrenadeItemID
        end)
    end
    return id
end

local function CheckResourceDownloaded()
    if resourceChecked then return end
    resourceChecked = true
    pcall(function()
        local download_util = require("client.slua.logic.download.puffer.download_util")
        local downloaded = download_util.IsDownloaded(GRENADE_SKIN_ID)
        if not downloaded then
            local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
            local PufferConst = require("client.slua.logic.download.puffer_const")
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {GRENADE_SKIN_ID})
        end
    end)
end

-- ========== 1. 手持持续强刷 ==========
function _G.RefreshGrenadeAvatar()
    local uCharacter = _G.getPlayerCharacter and _G.getPlayerCharacter() or nil
    if not uCharacter then
        local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and GD then uCharacter = GD.GetPlayerCharacter() end
    end
    if not slua.isValid(uCharacter) then return end

    local weapon = uCharacter:GetCurrentWeapon()
    if not weapon or not slua.isValid(weapon) then return end

    local DefineID = weapon.GetItemDefineID and weapon:GetItemDefineID()
    if not DefineID then return end
    local wid = DefineID.TypeSpecificID

    local comp = nil
    pcall(function() comp = weapon["GrenadeAvatarComponent"] end)
    if not comp then
        pcall(function() comp = weapon["GrenadeAvatarComponent_BP"] end)
    end
    if not slua.isValid(comp) then return end

    if wid == FRAG_GRENADE_ID then
        -- 强刷九尾
        if comp.PreChangeGrenadeAvatar then
            pcall(function() comp:PreChangeGrenadeAvatar(GRENADE_SKIN_ID) end)
        end
        if FORCE_WEAPON_ID and FORCE_WEAPON_ID > 0 then
            if comp.SetOverrideFxIndex then comp:SetOverrideFxIndex(tonumber(FORCE_WEAPON_ID)) end
            if comp.SetOverrideSoundIndex then comp:SetOverrideSoundIndex(0) end
        end
        _lastHandID = wid
    else
        -- 切走恢复默认
        if _lastHandID == FRAG_GRENADE_ID then
            if comp.PreChangeGrenadeAvatar then
                pcall(function() comp:PreChangeGrenadeAvatar(0) end)
            end
            _lastHandID = wid
        end
    end
end

-- ========== 2. 飞行中持续强刷 ==========
local function ScanFlyingGrenades()
    local PC = GetPC()
    if not PC then return end
    local world = PC:GetWorld()
    if not slua.isValid(world) then return end

    local FragClass = fragClass
    if not FragClass then
        local ok, cls = pcall(import, "FragGrenade")
        if ok and cls then FragClass = cls end
    end
    if not FragClass then return end

    pcall(function()
        local arr = UGameplayStatics.GetAllActorsOfClass(world, FragClass, {})
        if not arr then return end
        for _, actor in pairs(arr) do
            local itemID = GetActorItemID(actor)
            if itemID == FRAG_GRENADE_ID then
                CheckResourceDownloaded()
                local comp = nil
                for _, fname in ipairs({"GrenadeAvatarComponent_BP", "GrenadeAvatarComponent"}) do
                    pcall(function() comp = actor[fname] end)
                    if comp then break end
                end
                if comp and comp.PreChangeGrenadeAvatar then
                    pcall(function() comp:PreChangeGrenadeAvatar(GRENADE_SKIN_ID) end)
                end
            end
        end
    end)
end

-- ========== 3. 组件级 Hook ==========
local function PatchGrenadeAvatarComponent()
    local ok, mod = pcall(require, "GameLua.Mod.Library.GamePlay.Avatar.Component.GrenadeAvatarComponent")
    if not ok or not mod or not mod.__inner_impl then return false end
    local impl = mod.__inner_impl

    -- 切到手雷瞬间触发（比定时器 30Hz 还快）
    local orig = rawget(impl, "OnGrenadeAvatarEqiuped")
    if type(orig) == "function" and not rawget(impl, "__gfxOnEqV27") then
        rawset(impl, "__gfxOnEqV27", true)
        rawset(impl, "OnGrenadeAvatarEqiuped", function(self, ...)
            local r = orig(self, ...)
            pcall(function()
                local uCharacter = _G.getPlayerCharacter and _G.getPlayerCharacter()
                if uCharacter then
                    local weapon = uCharacter:GetCurrentWeapon()
                    if weapon then
                        local wid = weapon:GetItemDefineID().TypeSpecificID
                        if wid == FRAG_GRENADE_ID and self and self.PreChangeGrenadeAvatar then
                            self:PreChangeGrenadeAvatar(GRENADE_SKIN_ID)
                            if FORCE_WEAPON_ID and FORCE_WEAPON_ID > 0 then
                                if self.SetOverrideFxIndex then self:SetOverrideFxIndex(tonumber(FORCE_WEAPON_ID)) end
                                if self.SetOverrideSoundIndex then self:SetOverrideSoundIndex(0) end
                            end
                        end
                    end
                end
            end)
            return r
        end)
    end

    local origCheck = rawget(impl, "CheckHasOverrideFx")
    if type(origCheck) == "function" and not rawget(impl, "__gfxCheckFx") then
        rawset(impl, "__gfxCheckFx", true)
        rawset(impl, "CheckHasOverrideFx", function(self, ...)
            if FORCE_WEAPON_ID and FORCE_WEAPON_ID > 0 then
                local wid = tonumber(FORCE_WEAPON_ID)
                if self.SetOverrideFxIndex then self:SetOverrideFxIndex(wid) end
                if self.SetOverrideSoundIndex then self:SetOverrideSoundIndex(0) end
                return
            end
            return origCheck(self, ...)
        end)
    end
    fxHooked = true
    return true
end

-- ========== 4. 爆炸特效 ==========
local function spawnCustomFx(self, loc)
    local s = getGrenadeScale()
    if cachedSeqPath and cachedSeqPath ~= "" then
        local host = slua.isValid(self) and self or slua_GameFrontendHUD
        local tf = FTransform(FRotator(0, 0, 0), loc, FVector(s, s, s))
        local seq = Game:PlayLevelSequence(host, cachedSeqPath, tf,
            "/Game/Arts_PlayerBluePrints/DeadBox/DeadBoxSmoke/BP_DeadBoxSmokeSeqActor.BP_DeadBoxSmokeSeqActor_C", false)
        if slua.isValid(seq) then seq:Play(0.0); return true end
    end
    if slua.isValid(cachedParticle) then
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if slua.isValid(world) then
            UGameplayStatics.SpawnEmitterAtLocation(world, cachedParticle, loc,
                FRotator(0, 0, 0), FVector(s, s, s), true)
            return true
        end
    end
    return false
end

local function playExplosionSound(self, loc)
    pcall(function()
        local AkGameplayStatics = import("AkGameplayStatics")
        local sound = self.ExplosionSound or self.ExplodeSound
            or self.ExplosionAkEvent or self.ExplodeAkEvent
            or self.ExplosionSoundCue or self.ExplodeSoundCue
            or self.ExplosionAudio or self.ExplodeAudio
        if sound and slua.isValid(sound) then
            AkGameplayStatics.PostEventAtLocation(sound, loc, FRotator(0, 0, 0), "", self.Object)
        end
    end)
end

local function findFragGrenadeImpl()
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table"
            and path:find("FragGrenade") and not path:find("LuaGet") then
            local impl = mod.__inner_impl
            if type(impl) == "table" then
                local cur = impl
                while cur do
                    if type(rawget(cur, "BeginInEffect")) == "function" then return cur end
                    cur = cur.__super_impl
                end
            end
        end
    end
    return nil
end

local function InjectFxTable()
    if not FORCE_WEAPON_ID or FORCE_WEAPON_ID <= 0 then return end
    local ok, tbl = pcall(function() return CDataTable.GetTable("GrenadeBindWeaponFx") end)
    if not ok or type(tbl) ~= "table" then return end
    if tbl[FORCE_WEAPON_ID] and tbl[FORCE_WEAPON_ID].FxPath and tbl[FORCE_WEAPON_ID].FxPath ~= "" then return end
    local src = tbl[SOURCE_FX_ID]
    if src and src.FxPath and src.FxPath ~= "" then
        tbl[FORCE_WEAPON_ID] = {ID=FORCE_WEAPON_ID, FxPath=src.FxPath, FxSeqPath=src.FxSeqPath or ""}
    else
        tbl[FORCE_WEAPON_ID] = {ID=FORCE_WEAPON_ID, FxPath=FALLBACK_FX, FxSeqPath=""}
    end
end

function M.Apply()
    PatchGrenadeAvatarComponent()

    if not preloaded or preloadedForId ~= FORCE_WEAPON_ID then
        cachedParticle = nil
        cachedSeqPath = nil
        local ok2, fxCfg = pcall(function()
            return CDataTable.GetTableData("GrenadeBindWeaponFx", FORCE_WEAPON_ID)
        end)
        if ok2 and fxCfg then
            cachedSeqPath = fxCfg.FxSeqPath
            if fxCfg.FxPath and fxCfg.FxPath ~= "" then
                local util = require("client.slua_ui_framework.util")
                -- ★ 优先加载真实路径（去掉 _UI 后缀）
                local realPath = fxCfg.FxPath
                if realPath:find("_UI") then
                    realPath = realPath:gsub("_UI", "")
                end
                util.GetAssetAsync(realPath, function(uParticle)
                    if slua.isValid(uParticle) then
                        cachedParticle = uParticle
                        print("[GrenadeFX] ✓ 已加载真实8级粒子: " .. realPath)
                    else
                        print("[GrenadeFX] ✗ 真实路径失败，回退 _UI: " .. fxCfg.FxPath)
                        -- 回退到 _UI 版本
                        util.GetAssetAsync(fxCfg.FxPath, function(uParticle2)
                            if slua.isValid(uParticle2) then
                                cachedParticle = uParticle2
                                print("[GrenadeFX] ✓ 已加载 UI 粒子（预览版）")
                            end
                        end)
                    end
                end)
            end
        end
        preloaded = true
        preloadedForId = FORCE_WEAPON_ID
    end

    if not applied then
        local impl = findFragGrenadeImpl()
        if not impl then return false end
        local orig = rawget(impl, "BeginInEffect")
        if type(orig) ~= "function" then return false end
        rawset(impl, "BeginInEffect", function(self, OldType)
            pcall(function()
                if not fragClass then
                    local cls = self:GetClass()
                    if cls then fragClass = cls end
                end
            end)
            if not Client then
                orig(self, OldType)
                return
            end
            local loc = self.K2_GetActorLocation and self:K2_GetActorLocation() or nil
            if loc and spawnCustomFx(self, loc) then
                playExplosionSound(self, loc)
                return
            end
            orig(self, OldType)
        end)
        applied = true
    end
    return true
end

-- ★ 大小控制（写配置 + 立即生效）
function M.SetScale(scale)
    scale = tonumber(scale) or 1.0
    if scale < 0.5 then scale = 0.5 end
    if scale > 5.0 then scale = 5.0 end
    _G.GrenadeFX8_Scale = scale
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Set then
        _G.DazhiMH_Config.Set("GRENADE_FX_SCALE", math.floor(scale * 100 + 0.5))
    end
    return scale
end

function M.GetScale()
    return getGrenadeScale()
end

-- ★ 在角色位置测试 spawn
function M.TestSpawn()
    local ch = nil
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        ch = pc and pc:GetPlayerCharacterSafety()
    end)
    if not ch then return end
    if not slua.isValid(cachedParticle) then
        M.Apply()
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(2, function() M.TestSpawn() end)
        end
        return
    end
    local loc = nil
    pcall(function() loc = ch:K2_GetActorLocation() end)
    local world = slua_GameFrontendHUD:GetWorld()
    if loc and slua.isValid(world) then
        local s = getGrenadeScale()
        pcall(function()
            UGameplayStatics.SpawnEmitterAtLocation(world, cachedParticle, loc,
                FRotator(0, 0, 0), FVector(s, s, s), true)
        end)
    end
end

function _G.ApplyGrenadeSkin()
    if not GRENADE_SKIN_ID then return end
    local PC = GetPC()
    if not PC or not slua.isValid(PC.InitialConsumableAvatar) then return end
    if PC.InitialConsumableAvatar.GrenadeAvatarShoulei == GRENADE_SKIN_ID then return end
    if PC.InitGrenadeAvatarList then pcall(function() PC:InitGrenadeAvatarList(true) end) end
    if PC.InitialConsumableAvatar then
        PC.InitialConsumableAvatar.GrenadeAvatarShoulei = GRENADE_SKIN_ID
        if PC.InitGrenadeAvatarList then pcall(function() PC:InitGrenadeAvatarList() end) end
    end
end

pcall(function()
    local SkinCfg = CDataTable.GetTableData("GrenadeKillGunBindMap", GRENADE_SKIN_ID)
    if SkinCfg and SkinCfg.UnlockFxGunIDList_a and SkinCfg.UnlockFxGunIDList_a:Num() > 0 then
        FORCE_WEAPON_ID = SkinCfg.UnlockFxGunIDList_a:Get(0)
    else
        FORCE_WEAPON_ID = 1101006092
    end
    InjectFxTable()
    _G.ApplyGrenadeSkin()
    M.Apply()
end)

local ticker = _G.Mytimer_ticker
if not ticker then
    local ok, tt = pcall(require, "common.time_ticker")
    if ok and tt then ticker = tt end
end

if ticker then
    local _tick = 0
    local _lastGrenadeRefresh = 0
    -- 回调间隔 0.15 秒（每秒 6.7 次），比 0.05 秒轻 3 倍
    ticker.AddTimerLoop(0.15, function()
        local now = os.clock()
        -- ★ 默认每秒 1 次（和文件1一样，最稳）
        local interval = 1.0
        if _G.DazhiMH_Config and _G.DazhiMH_Config.Get and _G.DazhiMH_Config.Get("GRENADE_FAST_REFRESH", 0) == 1 then
            interval = 0.15  -- ★ 极速：每秒 6.7 次（受限于回调节奏）
        end
        
        if now - _lastGrenadeRefresh >= interval then
            _lastGrenadeRefresh = now
            _tick = _tick + 1
            pcall(function()
                if not applied or not fxHooked then M.Apply() end
                _G.ApplyGrenadeSkin()
                _G.RefreshGrenadeAvatar()
                if _tick % 2 == 0 then
                    ScanFlyingGrenades()
                end
            end)
        end
    end, -1, 0.15)
end

function M.Preload() end
function M.BindMaxWeapon(id) FORCE_WEAPON_ID = tonumber(id) or FORCE_WEAPON_ID end
function M.ListWeapons() end
function M.Fire() end
function M.SetGrenadeSkin(id) GRENADE_SKIN_ID = tonumber(id) or GRENADE_SKIN_ID end

end


-- ==================== 定时器初始化与启动 ====================
-- 将定时器模块赋值给全局变量，方便其他函数调用
_G.Mytimer_ticker = TXtime_ticker



-- ========== 日志函数 ==========
local function LOG(msg)
    local f = io.open("data/share1/loglua.txt", "a+")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(msg) .. "\n")
        f:close()
    end
end

-- ========== 引用必要模块 ==========
local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
local PufferConst = require("client.slua.logic.download.puffer_const")
local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local ECharacterHealthStatus = import("ECharacterHealthStatus")
local UEnums = _ENV.UEnums

_G.__ModTeamKillSkinID = _G.__ModTeamKillSkinID or 0
local TEAM_KILL_SUB_EFFECT = 22

-- ========== 下载资源函数 ==========
local function pufferDownload(id)
    if not id or id == 0 then return end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {id})
    if state ~= PufferConst.ENUM_DownloadState.Done then
        PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {id})
    end
end

-- 下载击杀特效资源
local function downloadEliminationAssets(skinID)
    pufferDownload(skinID)
    local cfg = CDataTable.GetTableData("WeaponAvatarBattleEffect", skinID)
    if cfg then
        if cfg.EffectPath and cfg.EffectPath ~= "" then pufferDownload(cfg.EffectPath) end
        if cfg.BgPath and cfg.BgPath ~= "" then pufferDownload(cfg.BgPath) end
    end
end

-- 下载队友击杀广播资源
local function downloadTeamAssets(skinID)
    pufferDownload(skinID)
    local cfg = CDataTable.GetTableData("TeamKillBroadcast", skinID)
    if cfg then
        if cfg.EffectPath and cfg.EffectPath ~= "" then pufferDownload(cfg.EffectPath) end
        if cfg.BgPath and cfg.BgPath ~= "" then pufferDownload(cfg.BgPath) end
    end
end

_G.download_item = downloadEliminationAssets




-- ==================== 击杀信息Hook（优化版） ====================
-- 使用稳定的 snn.lua 逻辑，避免重复Hook和模式冲突
if not _G.BattleKillBroadcastSkinHacked then
    pcall(function()
        local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")
        if not (BattleKillBroadcastSubSystem and BattleKillBroadcastSubSystem.__inner_impl) then return end
        local o_Copy = BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable
        BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
            local msgData = o_Copy(self, messageData)
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local character = pc and pc:GetPlayerCharacterSafety()
                if character and slua.isValid(character) and msgData.bIamCauser and _G.LuaStateWrapper then
                    msgData.bShowBottomBothSidesKillInfo = true
                    local weapon = character:GetCurrentWeapon()
                    if weapon and slua.isValid(weapon) then
                        local weapon_id = weapon:GetItemDefineID() and weapon:GetItemDefineID().TypeSpecificID or 0
                        if weapon_id ~= 0 then
                            local expand_data = slua.LuaArchiverDecode(_G.LuaStateWrapper, msgData.ExpandDataContent) or {}
                            local isClassic = false
                            local uGameState = slua_GameFrontendHUD:GetGameState()
                            if uGameState and slua.isValid(uGameState) then
                                local EGameModeType = import("EGameModeType")
                                if uGameState.GameModeType == EGameModeType.ETypicalGameMode then isClassic = true end
                            end
                            local syn_data = weapon.synData
                            if syn_data and slua.isValid(syn_data) then
                                local define_id = slua.IndexReference(syn_data:Get(7), "defineID")
                                if define_id and slua.isValid(define_id) then
                                    expand_data.CauserWeaponAvatarID = define_id.TypeSpecificID
                                end
                            end
                            if isClassic then
                                expand_data.KillCounterItemId = weapon_id
                                expand_data.KillCounterNum = _G.getKills and _G.getKills(weapon_id) or 0
                            end
                            msgData.bShowKillNum = true
                            msgData.ExpandDataContent = slua.LuaArchiverEncode(_G.LuaStateWrapper, expand_data)
                        end
                    end
                end
            end)
            return msgData
        end
        _G.BattleKillBroadcastSkinHacked = true
    end)
end





-- ==================== 个人资料伪造模块 ====================
-- 功能：段位、巅峰赛、赛季之旅徽章、等级、头像、头像框

-- ========== 征服者段位设置 ==========
local CURRENT_SEGMENT = 801          -- 801=征服者
local CONQUEROR_STARS = 91           -- 星星数
local CURRENT_RATING = 4200 + (CONQUEROR_STARS - 1) * 100  -- 13200分

-- ========== 生涯最高段位 ==========
local HISTORY_SEGMENT = 801

-- ========== 巅峰赛设置 ==========
local PEAK_CURRENT_SEGMENT = 1541    -- 当前巅峰段位
local PEAK_HISTORY_SEGMENT = 1301    -- 历史最高
local PEAK_RATING = 8000

-- ========== 赛季之旅徽章 ==========
local JOURNEY_BADGE_LEVEL = 17
local JOURNEY_BADGE_VISUAL_LEVEL = 3
local JOURNEY_BADGE_GLOW_TASKS = 3
local JOURNEY_GLOW_RANKS = { 701, 702, 703, 801 }
local ENABLE_SEASON_YEAR_BADGE = true
local SHOW_SEASON_SERIES_MEDAL = true
local SEASON_SERIES_SEGMENT = 0

-- ========== 个人资料底部数据 ==========
local SEASON_RATING = 8500
local SEASON_RANK = "44"
local ACHIEVEMENT_POINTS = 9500
local PLAYED_YEARS = 10
local CONQUEROR_TITLE_ID = 0

-- ========== 基础设置（会被定时器刷新） ==========
local PLAYER_LEVEL = 100
local AVATAR_ID = 30396
local AVATAR_BOX_ID = 2002901

-- ==================== 定时器刷新头像/等级 ====================
local function refresh_basic_data()
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            _G.DataMgr.roleData.level = PLAYER_LEVEL

            -- ★ 用户选过 → 用用户的选择；没选过 → 用默认值
            local userA = math.floor(tonumber(_G.__BeysaUserAvatarPick) or 0)
            local userB = math.floor(tonumber(_G.__BeysaUserFramePick)  or 0)
            local targetA = (userA > 0) and userA or AVATAR_ID
            local targetB = (userB > 0) and userB or AVATAR_BOX_ID

            _G.DataMgr.roleData.pic_url = targetA
            _G.DataMgr.roleData.headIconUrl = targetA
            _G.DataMgr.roleData.pic_url_check_open = true
            _G.DataMgr.roleData.cur_avatar_box_id = targetB
        end
    end)
end

if _G.Mytimer_ticker then
    -- 延迟2秒启动
    _G.Mytimer_ticker.AddTimer(2, refresh_basic_data)
    -- 每1秒刷新一次（防止被游戏覆盖）
    _G.Mytimer_ticker.AddTimerLoop(1, refresh_basic_data, -1, 1)
else
    refresh_basic_data()
end

-- ==================== 段位系统常量 ====================
local SEGMENT_TYPE = {
    solo = 1, double = 2, team = 3,
    fpp_solo = 4, fpp_double = 5, fpp_team = 6,
}
local RANK_MODES = { "solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad" }
local ZONE_COUNT = 6

local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
if not RoleInfoSystem then
    print("[SetRoleInfo] RoleInfoSystem not found - 后续模块照常加载")
end

local function log_msg(...)
    print("[SetRoleInfo]", ...)
end

-- ==================== 辅助函数 ====================
local function stars_from_rating(rating)
    rating = tonumber(rating) or 0
    if rating < 4200 then return 0 end
    return math.max(0, math.floor((rating - 4200) / 100) + 1)
end

local function rating_from_stars(stars)
    stars = tonumber(stars) or 0
    if stars <= 0 then return 0 end
    return 4200 + (stars - 1) * 100
end

local function is_self_uid(uid)
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return false end
    return tonumber(uid) == tonumber(DataMgr.roleData.uid)
end

local function get_fake_registertime()
    local ok, TimeUtil = pcall(require, "client.common.time_util")
    local now = (ok and TimeUtil and TimeUtil.GetServerTimeInSec and TimeUtil.GetServerTimeInSec()) or os.time()
    return now - (PLAYED_YEARS * 365 * 86400)
end

-- ==================== 征服者称号ID ====================
local function resolve_conqueror_title_id()
    if CONQUEROR_TITLE_ID and CONQUEROR_TITLE_ID > 0 then
        return CONQUEROR_TITLE_ID
    end
    local bestId, bestPri = nil, -1
    pcall(function()
        local tbl = CDataTable and CDataTable.GetTable and CDataTable.GetTable("SegmentTitleConfig")
        if not tbl then return end
        for id, cfg in pairs(tbl) do
            if cfg and not cfg.IfDefaultTitle then
                local pri = tonumber(cfg.Priority) or 0
                local tid = tonumber(cfg.ID) or tonumber(id)
                if tid and pri > bestPri then
                    bestPri = pri
                    bestId = tid
                end
            end
        end
    end)
    return bestId or 0
end

-- ==================== 构建假数据 ====================
local function build_zone_segments(seg)
    return {
        [SEGMENT_TYPE.solo] = seg,
        [SEGMENT_TYPE.double] = seg,
        [SEGMENT_TYPE.team] = seg,
        [SEGMENT_TYPE.fpp_solo] = seg,
        [SEGMENT_TYPE.fpp_double] = seg,
        [SEGMENT_TYPE.fpp_team] = seg,
    }
end

local function build_allzone_segment(seg)
    local t = {}
    for z = 1, ZONE_COUNT do
        t[z] = build_zone_segments(seg)
    end
    return t
end

local function build_rankdata(rating)
    local rd = {}
    local entry = { rank_rating = rating }
    for z = 1, ZONE_COUNT do
        rd[z] = {}
        for _, mode in ipairs(RANK_MODES) do
            rd[z][mode] = entry
        end
    end
    return rd
end

local function build_hsegment_title(titleId)
    if not titleId or titleId <= 0 then return nil end
    local det = {}
    for z = 1, ZONE_COUNT do
        det[z] = {}
        for modeId = 1, 6 do
            det[z][modeId] = { id = titleId }
        end
    end
    return det
end

-- ==================== 巅峰赛数据 ====================
local function build_peakgame_list(segmentId, maxSegmentId, rating)
    local ok, PeakGameConfig = pcall(require, "client.logic.PeakGame.PeakGameConfig")
    if not ok or not PeakGameConfig then return nil end
    local bt = PeakGameConfig.BattleType.Squad
    local list = {}
    for z = 1, ZONE_COUNT do
        list[z] = {
            [bt] = {
                rating = rating or PeakGameConfig.DefaultPeakGameRating,
                segment_id = segmentId or PeakGameConfig.DefaultPeakGameSegment,
                max_segment_id = maxSegmentId or segmentId or PeakGameConfig.DefaultPeakGameSegment,
            },
        }
    end
    return list
end

local function build_peakgame_segment_info(segmentId, maxSegmentId, rating)
    local list = build_peakgame_list(segmentId, maxSegmentId, rating)
    if not list then return nil end
    local seasonId = (DataMgr and DataMgr.season_id) or 0
    return { curr_season_id = seasonId, list = list }
end

local function build_peakgame_rating_info(segmentId, maxSegmentId, rating)
    return build_peakgame_list(segmentId, maxSegmentId, rating)
end

-- ==================== 赛季之旅徽章 ====================
local function build_season_year_badge(level)
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return nil end
    local EB = cfg.EBadgePartType
    local Done = cfg.ERankTaskStatus.Completed
    level = tonumber(level) or 1

    local gem = { [1] = { finish_count = level, status = Done } }
    local base = { [1] = { finish_count = level, status = Done } }

    local glowTasks = tonumber(JOURNEY_BADGE_GLOW_TASKS) or 3
    local glow = {}
    for i = 1, glowTasks do
        glow[i] = {
            finish_count = 1,
            status = Done,
            trigger_value = JOURNEY_GLOW_RANKS[i] or 801,
        }
    end

    local crown = {}
    local crownMax = cfg.CrownTaskMaxCount or 10
    local crownStage = math.min(tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3, level)
    for i = 1, crownMax do
        crown[i] = { finish_count = crownStage, status = Done }
    end

    return {
        [EB.Gem] = gem,
        [EB.Base] = base,
        [EB.Glow] = glow,
        [EB.Crown] = crown,
    }
end

local function get_season_year_id()
    local ok, season_year_util = pcall(require, "client.logic.season_year.util.season_year_util")
    if ok and season_year_util and season_year_util.GetSeasonYearId then
        return season_year_util.GetSeasonYearId()
    end
    return 1
end

local function get_season_series_segment_id()
    if tonumber(SEASON_SERIES_SEGMENT) and SEASON_SERIES_SEGMENT > 0 then
        return SEASON_SERIES_SEGMENT
    end
    local segId
    pcall(function()
        local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
        if logic_leisure_season and logic_leisure_season.GetLeisureDefaultID then
            segId = logic_leisure_season:GetLeisureDefaultID()
        end
    end)
    if not segId or segId == 0 then
        pcall(function()
            local row = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("LeisureSeasonParamCfg", "MinSegmentId")
            if row and row.Value then segId = tonumber(row.Value) end
        end)
    end
    return segId or 101
end

-- ==================== 徽章UI渲染 ====================
local function badge_for_widget_render(badgeData)
    if not badgeData then return nil end
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return badgeData end
    local EB = cfg.EBadgePartType
    local Done = cfg.ERankTaskStatus.Completed
    local vis = math.min(3, tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3)
    local out = {}
    for partType, partInfo in pairs(badgeData) do
        out[partType] = {}
        for taskId, taskInfo in pairs(partInfo) do
            local fc = taskInfo.finish_count
            local st = taskInfo.status or Done
            if partType == EB.Gem or partType == EB.Base then
                fc = vis
            elseif partType == EB.Glow then
                fc = 1
            elseif partType == EB.Crown then
                fc = vis
            end
            out[partType][taskId] = {
                finish_count = fc,
                status = st,
                trigger_value = taskInfo.trigger_value,
            }
        end
    end
    return out
end

local function get_display_badge()
    local full = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    if not full then return nil end
    return badge_for_widget_render(full)
end

-- ==================== 服务器缓存 ====================
local apply_server_badge_cfg_cache

local function get_fake_badge_part_cfg()
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return {} end
    local yearId = get_season_year_id()
    if _G.SetRoleInfo_badge_part_cfg and _G.SetRoleInfo_badge_part_cfg[yearId] then
        return _G.SetRoleInfo_badge_part_cfg[yearId]
    end
    apply_server_badge_cfg_cache()
    return (_G.SetRoleInfo_badge_part_cfg and _G.SetRoleInfo_badge_part_cfg[yearId]) or {}
end

local function build_badge_part_cfg_list(count, stageId)
    local list = {}
    for i = 1, count do
        list[i] = {
            task_id = i,
            task_stage_id = stageId,
            finish_value = stageId,
            badge_cfg = { task_desc_id = 0, task_title_id = 0 },
        }
    end
    return list
end

apply_server_badge_cfg_cache = function()
    pcall(function()
        local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
        if not ok or not cfg then return end
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        local yearId = get_season_year_id()
        local EB = cfg.EBadgePartType
        local stage = math.min(3, tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3)
        logic_season_year_badge.serverBadgeCfg = logic_season_year_badge.serverBadgeCfg or {}
        logic_season_year_badge.serverBadgeCfg[yearId] = {
            [EB.Gem] = build_badge_part_cfg_list(1, stage),
            [EB.Base] = build_badge_part_cfg_list(1, stage),
            [EB.Glow] = build_badge_part_cfg_list(JOURNEY_BADGE_GLOW_TASKS, 1),
            [EB.Crown] = build_badge_part_cfg_list(cfg.CrownTaskMaxCount or 10, stage),
        }
        logic_season_year_badge.seasonYearTaskInfo = logic_season_year_badge.seasonYearTaskInfo or {}
        logic_season_year_badge.seasonYearTaskInfo[1] = {
            task_id = 1,
            status = cfg.ERankTaskStatus.Completed,
            finish_count = JOURNEY_BADGE_LEVEL,
        }
        local taskYearId = yearId
        logic_season_year_badge.serverYearTaskCfg = logic_season_year_badge.serverYearTaskCfg or {}
        logic_season_year_badge.serverYearTaskCfg[taskYearId] = {
            task_cfgs = {
                [1] = {
                    reward_itemid_1 = 0,
                    reward_cnt_1 = 0,
                    reward_valid_hours_1 = 0,
                    task_desc_id = 0,
                },
            },
        }
        _G.SetRoleInfo_badge_part_cfg = _G.SetRoleInfo_badge_part_cfg or {}
        _G.SetRoleInfo_badge_part_cfg[yearId] = logic_season_year_badge.serverBadgeCfg[yearId]
    end)
end

local function cache_badge_all_year_ids(displayBadge)
    if not displayBadge then return end
    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        logic_season_year_badge.seasonYearBadgeInfo = logic_season_year_badge.seasonYearBadgeInfo or {}
        local ids = {}
        local yid = get_season_year_id()
        ids[yid] = true
        if yid == 0 then ids[1] = true end
        pcall(function()
            if DataMgr and DataMgr.season_id and CDataTable and CDataTable.GetTableData then
                local row = CDataTable.GetTableData("SeasonInfo", DataMgr.season_id)
                if row and row.SeasonYearID then ids[row.SeasonYearID] = true end
            end
        end)
        for id, _ in pairs(ids) do
            logic_season_year_badge.seasonYearBadgeInfo[id] = displayBadge
        end
    end)
end

-- ==================== Ace印记 ====================
local function apply_ace_imprint_self()
    local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
    local baseId = 10
    local showCnt = tonumber(JOURNEY_BADGE_LEVEL) or 17
    local showId = baseId + showCnt
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.ace_show_type = ace_config.EAceShowType.Honer
        DataMgr.roleData.ace_imprint_base_id = baseId
        DataMgr.roleData.ace_imprint_show_id = showId
        DataMgr.roleData.ace_imprint_show_cnt = showCnt
    end
    if DataMgr then
        DataMgr.ace_show_type = ace_config.EAceShowType.Honer
        DataMgr.ace_imprint_base_id = baseId
        DataMgr.ace_imprint_show_id = showId
        DataMgr.ace_imprint_show_cnt = showCnt
    end
    pcall(function()
        if LobbySystem and LobbySystem.roleData then
            LobbySystem.roleData.ace_show_type = ace_config.EAceShowType.Honer
            LobbySystem.roleData.ace_imprint_base_id = baseId
            LobbySystem.roleData.ace_imprint_show_id = showId
            LobbySystem.roleData.ace_imprint_show_cnt = showCnt
        end
    end)
end

-- ==================== 徽章UI辅助 ====================
local function try_set_badge_center_number(badge_ui, num)
    if not badge_ui or not badge_ui.UIRoot then return end
    local root = badge_ui.UIRoot
    local textNames = {
        "TextBlock_Level", "TextBlock_Num", "TextBlock_Number", "TextBlock_Num04",
        "TextBlock_Gem", "TextBlock_0", "TextBlock_1", "TextBlock_5", "TextBlock_6",
        "TextBlock_3", "TextBlock_4",
    }
    local str = tostring(num)
    local function try_widget(w)
        if w and w.SetText then
            w:SetText(str)
            return true
        end
    end
    for _, name in ipairs(textNames) do
        if try_widget(root[name]) then return end
    end
    for lv = 0, 3 do
        local panel = root["Panel_GemCrown" .. lv]
        if panel then
            for _, name in ipairs(textNames) do
                if try_widget(panel[name]) then return end
            end
        end
    end
end

local function hide_kingmark_placeholder(root)
    if not root then return end
    pcall(function()
        if root.Image_69 then
            root.Image_69:SetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end)
end

local function apply_journey_kingmark_fallback(ui)
    if not ui or not ui.UIRoot or not ui.UIRoot.SizeBox_Badge_Root then return false end
    local root = ui.UIRoot
    local box = root.SizeBox_Badge_Root
    pcall(function()
        if ui._SetRoleInfo_journey_kingmark and ui._SetRoleInfo_journey_kingmark.Close then
            ui._SetRoleInfo_journey_kingmark:Close()
        end
    end)
    local child = nil
    pcall(function()
        if UIManager and UIManager.UI_Config and UIManager.UI_Config.Common_KingMark_UIBP_2 then
            child = ui:CreateChildWindow(box, UIManager.UI_Config.Common_KingMark_UIBP_2, 4)
        end
    end)
    if not child then
        pcall(function()
            local UIComponentModule = require("client.slua.component.UIComponentModule.UIComponentModule")
            if UIComponentModule and UIComponentModule.InitWithParentComponent then
                child = UIComponentModule:InitWithParentComponent(
                    ui, UIComponentModule.Config.Common_KingMark_UIBP_2, box, 4
                )
            end
        end)
    end
    if child and child.SetWidgetInfo then
        ui._SetRoleInfo_journey_kingmark = child
        child:SetWidgetInfo(10, { advance_num = JOURNEY_BADGE_LEVEL, history_num = 0 })
        try_set_badge_center_number(child, JOURNEY_BADGE_LEVEL)
        pcall(function()
            if child.Show then child:Show() end
            if child.UIRoot and child.UIRoot.SetVisibility then
                child.UIRoot:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
        end)
        return true
    end
    return false
end

local function apply_journey_season_badge_widget(ui, renderBadge)
    if not ui or not ui.UIRoot or not renderBadge then return false end
    local root = ui.UIRoot
    local box = root.SizeBox_Badge_Root
    if not box then return false end

    local ok_apply = false
    if ui.season_year_badge and ui.season_year_badge.SetBadgeInfo then
        ui.season_year_badge:SetBadgeInfo(renderBadge, false)
        try_set_badge_center_number(ui.season_year_badge, JOURNEY_BADGE_LEVEL)
        ok_apply = true
    end

    if not ok_apply and UIManager and UIManager.UI_Config and UIManager.UI_Config.Lobby_Season_Badge_Item_UIBP then
        pcall(function()
            if ui.season_year_badge and ui.CloseChildWindow then
                ui:CloseChildWindow(ui.season_year_badge)
            end
        end)
        ui.season_year_badge = nil
        pcall(function()
            ui.season_year_badge = ui:CreateChildWindow(
                box, UIManager.UI_Config.Lobby_Season_Badge_Item_UIBP, renderBadge
            )
        end)
        if (not ui.season_year_badge) then
            pcall(function()
                local UIComponentModule = require("client.slua.component.UIComponentModule.UIComponentModule")
                if UIComponentModule and UIComponentModule.InitWithParentComponent then
                    ui.season_year_badge = UIComponentModule:InitWithParentComponent(
                        ui, UIComponentModule.Config.SeasonYear_Badge_Item_UIBP, box, renderBadge
                    )
                end
            end)
        end
        if ui.season_year_badge and ui.season_year_badge.SetBadgeInfo then
            ui.season_year_badge:SetBadgeInfo(renderBadge, false)
            try_set_badge_center_number(ui.season_year_badge, JOURNEY_BADGE_LEVEL)
            ok_apply = true
        end
    end
    return ok_apply
end

-- ==================== 应用段位到个人资料 ====================
local function apply_history_max_segment(profile)
    if not profile or type(profile) ~= "table" then return end
    profile.history_max_segment_level = profile.history_max_segment_level or {}
    profile.history_max_segment_season_id = profile.history_max_segment_season_id or {}
    for z = 1, ZONE_COUNT do
        profile.history_max_segment_level[z] = HISTORY_SEGMENT
        profile.history_max_segment_season_id[z] = profile.history_max_segment_season_id[z]
            or (DataMgr and DataMgr.season_id) or 0
    end
end

local function get_star_rating()
    if tonumber(CURRENT_SEGMENT) ~= 801 then
        return tonumber(CURRENT_RATING) or 0
    end
    local stars = tonumber(DISPLAY_STARS) or 0
    if stars > 0 then
        return rating_from_stars(stars)
    end
    return tonumber(CURRENT_RATING) or 0
end

local function apply_profile_badge_fields(profile)
    if not profile or type(profile) ~= "table" then return end
    local fullBadge = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    local displayBadge = fullBadge and badge_for_widget_render(fullBadge) or nil
    if fullBadge then
        profile.season_year_badge_info = fullBadge
        local yearId = get_season_year_id()
        profile.season_year_badge = profile.season_year_badge or {}
        profile.season_year_badge[yearId] = displayBadge or fullBadge
    end
    local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
    profile.ace_show_type = ace_config.EAceShowType.Honer
    profile.ace_imprint_base_id = 10
    profile.ace_imprint_show_id = 10 + JOURNEY_BADGE_LEVEL
    profile.ace_imprint_show_cnt = JOURNEY_BADGE_LEVEL
    profile.casual_segment_id = get_season_series_segment_id()
end

local function apply_profile_rank_fields(profile)
    if not profile or type(profile) ~= "table" then return end
    local titleId = resolve_conqueror_title_id()
    local rating = get_star_rating()

    profile.segment_info = build_allzone_segment(CURRENT_SEGMENT)
    profile.rankdata = build_rankdata(rating)
    profile.cur_max_segment_level = CURRENT_SEGMENT
    apply_history_max_segment(profile)

    local htitle = build_hsegment_title(titleId)
    if htitle then
        profile.hsegment_title_det = htitle
    end

    local peakInfo = build_peakgame_segment_info(PEAK_CURRENT_SEGMENT, PEAK_CURRENT_SEGMENT, PEAK_RATING)
    if peakInfo then
        profile.peakgame_segment_info = peakInfo
    end
    profile.peakgame_history_max_segment = PEAK_HISTORY_SEGMENT
end

local function apply_profile_extras(profile)
    if not profile or type(profile) ~= "table" then return end
    apply_profile_rank_fields(profile)
    apply_profile_badge_fields(profile)
    if is_self_uid(profile.uid) then
        profile.registertime = get_fake_registertime()
    end
end

-- ==================== 强制徽章 ====================
local function ensure_force_badge()
    local full = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    if full then
        _G.SetRoleInfo_force_badge_full = full
        _G.SetRoleInfo_force_badge = get_display_badge() or badge_for_widget_render(full)
    end
    return _G.SetRoleInfo_force_badge
end

local function apply_season_year_badge_cache()
    if not ENABLE_SEASON_YEAR_BADGE then return end
    local displayBadge = ensure_force_badge()
    if not displayBadge then return end
    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        cache_badge_all_year_ids(displayBadge)
        logic_season_year_badge.loginDays = JOURNEY_BADGE_LEVEL
        local cfg = require("client.logic.season_year.config.season_year_config")
        logic_season_year_badge.badgeShowType = cfg.EBadgeShowType.Show
        apply_server_badge_cfg_cache()
        apply_ace_imprint_self()
    end)
end

-- ==================== UI强制刷新 ====================
local function force_classic_career_highest(ui)
    if not ui or not ui.UIRoot then return end
    local root = ui.UIRoot
    local seasonId = (DataMgr and DataMgr.season_id) or 0
    local w = root.Common_RankIntegralLevel_Style_Large_UIBP_C_2
    if not w then return end
    pcall(function()
        if w.SetRankInteralBySeason then
            w:SetRankInteralBySeason(HISTORY_SEGMENT, nil, seasonId)
        elseif w.SetRankInteralWithSegmentTitle then
            w:SetRankInteralWithSegmentTitle(HISTORY_SEGMENT, nil, seasonId, 0, get_star_rating())
        elseif w.SetRankInteral then
            w:SetRankInteral(HISTORY_SEGMENT, nil)
        end
    end)
end

local function force_roleinfo_journey_badge(ui)
    if not ui or not ui.UIRoot then return end
    local root = ui.UIRoot
    local renderBadge = ensure_force_badge()
    if not renderBadge then return end

    if LocUtil and root.TextBlock_47 then
        pcall(function() root.TextBlock_47:SetText(LocUtil.GetLocalizeResStr(85103)) end)
    end
    if root.TextBlock_21 and LocUtil then
        pcall(function() root.TextBlock_21:SetText(LocUtil.GetLocalizeResStr(68405)) end)
    end
    ui:SetWidgetVisible(root.SizeBox_Badge_Root, true)
    hide_kingmark_placeholder(root)
    if root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
        ui:SetWidgetVisible(root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, SHOW_SEASON_SERIES_MEDAL)
    end

    local ok = apply_journey_season_badge_widget(ui, renderBadge)
    if not ok then
        apply_journey_kingmark_fallback(ui)
    end
end

local function force_roleinfo_profile_slots(ui)
    force_classic_career_highest(ui)
    force_roleinfo_journey_badge(ui)
end

local function apply_roleinfo_badges_ui()
    apply_season_year_badge_cache()
    pcall(function()
        local ui = UIManager.GetUI(UIManager.UI_Config.roleinfo_segment)
        if not ui or not ui.UIRoot then return end
        local root = ui.UIRoot

        force_roleinfo_profile_slots(ui)

        if SHOW_SEASON_SERIES_MEDAL and root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
            ui:SetWidgetVisible(root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, true)
            local leisure_season_util = require("client.slua.logic.leisure.leisure_season_util")
            leisure_season_util.SetRankBigIcon(
                root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1,
                get_season_series_segment_id()
            )
            if ui.RefreshCasualSegment then
                ui:RefreshCasualSegment()
            end
        end
    end)
end

-- ==================== DataMgr数据注入 ====================
local function apply_data_mgr_ranks()
    if not DataMgr or not DataMgr.roleData then return end
    local rd = DataMgr.roleData
    local cur = CURRENT_SEGMENT
    local rating = get_star_rating()

    rd.segment = rd.segment or {}
    rd.segment.solo = cur
    rd.segment.double = cur
    rd.segment.team = cur
    rd.segment.fpp_solo = cur
    rd.segment.fpp_double = cur
    rd.segment.fpp_team = cur
    rd.allzoneSegment = build_allzone_segment(cur)

    rd.rankdata = build_rankdata(rating)

    local titleId = resolve_conqueror_title_id()
    if titleId > 0 then
        rd.allzoneSegmentTitle = build_hsegment_title(titleId)
    end

    DataMgr.isSeasonStarOpen = true
    rd.is_season_star_open = true

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        SeasonSystem.segment.team.level = cur
        SeasonSystem.segment.team.rating = rating
    end)

    pcall(function()
        DataMgr.maxSegmentSquad = DataMgr.maxSegmentSquad or { zoneid = 1, SegmentLevel = 0 }
        DataMgr.maxSegmentSquad.SegmentLevel = cur
        DataMgr.maxSegmentSquad.zoneid = 1
    end)

    local peakList = build_peakgame_rating_info(PEAK_CURRENT_SEGMENT, PEAK_CURRENT_SEGMENT, PEAK_RATING)
    if peakList then
        rd.peakgame_rating_info = peakList
    end
    rd.peakgame_history_max_segment = PEAK_HISTORY_SEGMENT
    rd.casual_segment_id = get_season_series_segment_id()
    DataMgr.registertime = get_fake_registertime()
end

local function apply_personal_basic()
    local ok, RoleInfoMainSystem = pcall(require, "client.logic.roleinfo.logic_new_roleinfo")
    if not ok or not RoleInfoMainSystem then return end
    local pbi = RoleInfoSystem.PersonalBasicInfo
    if not pbi or type(pbi) ~= "table" then return end

    pbi.all_segment_info = build_allzone_segment(CURRENT_SEGMENT)
    local titleId = resolve_conqueror_title_id()
    if titleId > 0 then
        pbi.hsegment_title_det = build_hsegment_title(titleId)
    end

    local zoneId = 1
    if RoleInfoMainSystem.GetShowRoleinfoOfZoneID then
        zoneId = RoleInfoMainSystem.GetShowRoleinfoOfZoneID() or 1
    end
    if zoneId == 0 then zoneId = 1 end
    local zs = pbi.all_segment_info[zoneId]
    if zs then
        local fields = {
            "role_segment_solo", "role_segment_double", "role_segment_team",
            "role_segmentFPP_solo", "role_segmentFPP_double", "role_segmentFPP_team",
            "curr_role_segment_solo", "curr_role_segment_double", "curr_role_segment_team",
            "curr_role_segmentFPP_solo", "curr_role_segmentFPP_double", "curr_role_segmentFPP_team",
        }
        local vals = {
            zs[SEGMENT_TYPE.solo], zs[SEGMENT_TYPE.double], zs[SEGMENT_TYPE.team],
            zs[SEGMENT_TYPE.fpp_solo], zs[SEGMENT_TYPE.fpp_double], zs[SEGMENT_TYPE.fpp_team],
            zs[SEGMENT_TYPE.solo], zs[SEGMENT_TYPE.double], zs[SEGMENT_TYPE.team],
            zs[SEGMENT_TYPE.fpp_solo], zs[SEGMENT_TYPE.fpp_double], zs[SEGMENT_TYPE.fpp_team],
        }
        for i, f in ipairs(fields) do
            pbi[f] = vals[i]
        end
    end
    pbi.role_all_zone_segment_max = CURRENT_SEGMENT
end

-- ==================== 最终应用 ====================
local function apply_extra_settings()
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.level = PLAYER_LEVEL

        -- ★ 用户选过 → 用用户的选择；没选过 → 用默认值
        local userA = math.floor(tonumber(_G.__BeysaUserAvatarPick) or 0)
        local userB = math.floor(tonumber(_G.__BeysaUserFramePick)  or 0)
        local targetA = (userA > 0) and userA or AVATAR_ID
        local targetB = (userB > 0) and userB or AVATAR_BOX_ID

        DataMgr.roleData.pic_url = targetA
        DataMgr.roleData.headIconUrl = targetA
        DataMgr.roleData.pic_url_check_open = true
        DataMgr.roleData.cur_avatar_box_id = targetB
        print("[SetRoleInfo] 已设置: 等级=" .. tostring(PLAYER_LEVEL)
              .. ", 头像=" .. tostring(targetA)
              .. ", 头像框=" .. tostring(targetB))
    end
end

local function apply_history_to_self_caches()
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
    local uid = tonumber(DataMgr.roleData.uid)
    local ok, logic_profile = pcall(function()
        return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    end)
    if ok and logic_profile then
        for _, bucket in ipairs({ logic_profile.dicFriend, logic_profile.dicStranger }) do
            if bucket and bucket[uid] then
                apply_profile_extras(bucket[uid])
            end
        end
        local profile = logic_profile:GetLocalProfile(uid) or logic_profile:GetLocalProfile(uid, true)
        if profile then
            apply_profile_extras(profile)
        end
    end
end

-- ==================== UI补丁 ====================
local function patch_conqueror_star_ui()
    if _G.SetRoleInfo_star_ui_patched then return end

    pcall(function()
        local RIClass = require("client.slua.umg.rankIntegral.RankIntegralIconSmall")
        if RIClass and RIClass.SetRankInteralWithSegmentTitle and not RIClass._SetRoleInfo_orig_RII then
            RIClass._SetRoleInfo_orig_RII = RIClass.SetRankInteralWithSegmentTitle
            RIClass.SetRankInteralWithSegmentTitle = function(self, segment, textName, seasonId, titleId, rating)
                if tonumber(segment) == 801 and (not rating or tonumber(rating) == 0) then
                    rating = get_star_rating()
                end
                return RIClass._SetRoleInfo_orig_RII(self, segment, textName, seasonId, titleId, rating)
            end
        end
    end)

    pcall(function()
        local BaseClass = require("client.slua.umg.rankIntegral.RankSmall_Sub_Base_UIBP")
        if BaseClass and BaseClass.SetRankInteralWithSegmentTitle and not BaseClass._SetRoleInfo_orig_Base then
            BaseClass._SetRoleInfo_orig_Base = BaseClass.SetRankInteralWithSegmentTitle
            BaseClass.SetRankInteralWithSegmentTitle = function(self)
                if tonumber(self.rankIntegral) == 801 and (not self.rating or tonumber(self.rating) == 0) then
                    self.rating = get_star_rating()
                end
                return BaseClass._SetRoleInfo_orig_Base(self)
            end
        end
    end)

    pcall(function()
        local logic_segment_title = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_segment_title)
        if logic_segment_title and not logic_segment_title._SetRoleInfo_orig_MaxTitle then
            logic_segment_title._SetRoleInfo_orig_MaxTitle = logic_segment_title.SetMaxSegmentRankInteralWithTitle
            logic_segment_title.SetMaxSegmentRankInteralWithTitle = function(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                if not slua.isValid(widget) or not allSegmentInfo then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                local maxSegment, zoneid, modeid = self:GetMaxSegementLevelWithZoneAndModeId(allSegmentInfo)
                if not maxSegment or maxSegment <= 0 then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                if seasonId and seasonId ~= 0 and seasonId ~= DataMgr.season_id then
                    widget:SetRankInteralBySeason(maxSegment, nil, seasonId)
                    return
                end
                local segmentTitleId = self:GetSegmentTitleId(allZoneSegmentTitle, zoneid, modeid)
                local rating = (tonumber(maxSegment) == 801) and get_star_rating() or nil
                local sid = seasonId or DataMgr.season_id
                if not segmentTitleId or tonumber(segmentTitleId) == 0 then
                    if rating and rating > 0 then
                        widget:SetRankInteralWithSegmentTitle(maxSegment, nil, sid, 0, rating)
                    else
                        widget:SetRankInteralBySeason(maxSegment, nil, sid)
                    end
                else
                    widget:SetRankInteralWithSegmentTitle(maxSegment, nil, sid, segmentTitleId, rating)
                end
            end
        end
    end)

    pcall(function()
        local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
        if LobbySocialSystem and not LobbySocialSystem._SetRoleInfo_self_prof then
            LobbySocialSystem._SetRoleInfo_self_prof = true
            local orig = LobbySocialSystem.GetSelfProfile
            LobbySocialSystem.GetSelfProfile = function()
                local p = orig()
                if p and tonumber(CURRENT_SEGMENT) == 801 then
                    p.rankdata = build_rankdata(get_star_rating())
                end
                if p and ENABLE_SEASON_YEAR_BADGE then
                    apply_profile_badge_fields(p)
                end
                return p
            end
        end
        if LobbySocialSystem and LobbySocialSystem.GetAceImprintShowId and not LobbySocialSystem._SetRoleInfo_ace_show then
            LobbySocialSystem._SetRoleInfo_ace_show = true
            local origAce = LobbySocialSystem.GetAceImprintShowId
            LobbySocialSystem.GetAceImprintShowId = function(uid)
                if is_self_uid(uid) and ENABLE_SEASON_YEAR_BADGE then
                    return 10 + JOURNEY_BADGE_LEVEL, 10, JOURNEY_BADGE_LEVEL
                end
                return origAce(uid)
            end
        end
    end)

    pcall(function()
        local SeasonHandler = require("client.network.Protocol.SeasonHandler")
        SeasonHandler.rank_rating = get_star_rating()
    end)

    _G.SetRoleInfo_star_ui_patched = true
end

-- ==================== 徽章和休闲赛季补丁 ====================
local function patch_badge_and_leisure_hooks()
    if _G.SetRoleInfo_badge_hooks_patched then return end
    _G.SetRoleInfo_badge_hooks_patched = true

    pcall(function()
        local season_year_util = require("client.logic.season_year.util.season_year_util")
        if season_year_util and season_year_util.CheckFunctionIsOpen and not season_year_util._SetRoleInfo_orig_CheckOpen then
            season_year_util._SetRoleInfo_orig_CheckOpen = season_year_util.CheckFunctionIsOpen
            season_year_util.CheckFunctionIsOpen = function()
                if ENABLE_SEASON_YEAR_BADGE then return true end
                return season_year_util._SetRoleInfo_orig_CheckOpen()
            end
        end
    end)

    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if logic_season_year_badge and logic_season_year_badge.GetCurSeasonYearBadgeInfo
            and not logic_season_year_badge._SetRoleInfo_orig_GetBadge then
            logic_season_year_badge._SetRoleInfo_orig_GetBadge = logic_season_year_badge.GetCurSeasonYearBadgeInfo
            local origGetBadge = logic_season_year_badge._SetRoleInfo_orig_GetBadge
            logic_season_year_badge.GetCurSeasonYearBadgeInfo = function(self)
                apply_season_year_badge_cache()
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                local data = origGetBadge(self)
                if ENABLE_SEASON_YEAR_BADGE and (not data or not next(data)) then
                    return ensure_force_badge() or data
                end
                return data
            end
        end
        if logic_season_year_badge and logic_season_year_badge.on_get_season_year_badge_info_rsp
            and not logic_season_year_badge._SetRoleInfo_wrapped_badge_rsp then
            logic_season_year_badge._SetRoleInfo_wrapped_badge_rsp = true
            local orig = logic_season_year_badge.on_get_season_year_badge_info_rsp
            logic_season_year_badge.on_get_season_year_badge_info_rsp = function(self, badge_info)
                if ENABLE_SEASON_YEAR_BADGE then
                    apply_season_year_badge_cache()
                    if EventSystem and EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
                        EventSystem:postEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
                    end
                    return
                end
                orig(self, badge_info)
            end
        end
        if logic_season_year_badge and logic_season_year_badge.on_get_season_year_badge_cfg_rsp
            and not logic_season_year_badge._SetRoleInfo_wrapped_cfg_rsp then
            logic_season_year_badge._SetRoleInfo_wrapped_cfg_rsp = true
            local origCfg = logic_season_year_badge.on_get_season_year_badge_cfg_rsp
            logic_season_year_badge.on_get_season_year_badge_cfg_rsp = function(self, info)
                origCfg(self, info)
                apply_server_badge_cfg_cache()
            end
        end
        if logic_season_year_badge and logic_season_year_badge.GetBadgeShowType
            and not logic_season_year_badge._SetRoleInfo_orig_ShowType then
            logic_season_year_badge._SetRoleInfo_orig_ShowType = logic_season_year_badge.GetBadgeShowType
            logic_season_year_badge.GetBadgeShowType = function(self)
                if ENABLE_SEASON_YEAR_BADGE then
                    local cfg = require("client.logic.season_year.config.season_year_config")
                    return cfg.EBadgeShowType.Show
                end
                return logic_season_year_badge._SetRoleInfo_orig_ShowType(self)
            end
        end
        if logic_season_year_badge and logic_season_year_badge.GetCurSeasonYearBadgeCfg
            and not logic_season_year_badge._SetRoleInfo_orig_GetCfg then
            logic_season_year_badge._SetRoleInfo_orig_GetCfg = logic_season_year_badge.GetCurSeasonYearBadgeCfg
            logic_season_year_badge.GetCurSeasonYearBadgeCfg = function(self)
                apply_server_badge_cfg_cache()
                local cfg = logic_season_year_badge._SetRoleInfo_orig_GetCfg(self)
                if cfg and next(cfg) then return cfg end
                local yearId = get_season_year_id()
                return self.serverBadgeCfg and self.serverBadgeCfg[yearId] or {}
            end
        end
    end)

    pcall(function()
        local season_year_badge_util = require("client.logic.season_year.util.season_year_badge_util")
        if season_year_badge_util.CheckGotBadge and not season_year_badge_util._SetRoleInfo_orig_Got then
            season_year_badge_util._SetRoleInfo_orig_Got = season_year_badge_util.CheckGotBadge
            season_year_badge_util.CheckGotBadge = function(badgeData)
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return true
                end
                return season_year_badge_util._SetRoleInfo_orig_Got(badgeData)
            end
        end
        if season_year_badge_util.GetBadgeShowType and not season_year_badge_util._SetRoleInfo_orig_UtilShow then
            season_year_badge_util._SetRoleInfo_orig_UtilShow = season_year_badge_util.GetBadgeShowType
            season_year_badge_util.GetBadgeShowType = function()
                if ENABLE_SEASON_YEAR_BADGE then
                    local cfg = require("client.logic.season_year.config.season_year_config")
                    return cfg.EBadgeShowType.Show
                end
                return season_year_badge_util._SetRoleInfo_orig_UtilShow()
            end
        end
        if season_year_badge_util.GetCurSeasonYearBadgeInfo and not season_year_badge_util._SetRoleInfo_orig_GetInfo then
            season_year_badge_util._SetRoleInfo_orig_GetInfo = season_year_badge_util.GetCurSeasonYearBadgeInfo
            season_year_badge_util.GetCurSeasonYearBadgeInfo = function()
                apply_season_year_badge_cache()
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                local data = season_year_badge_util._SetRoleInfo_orig_GetInfo()
                if ENABLE_SEASON_YEAR_BADGE and (not data or not next(data)) then
                    return ensure_force_badge() or data
                end
                return data
            end
        end
        if season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo and not season_year_badge_util._SetRoleInfo_orig_PartCfg then
            season_year_badge_util._SetRoleInfo_orig_PartCfg = season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo
            season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo = function(partType)
                local c = season_year_badge_util._SetRoleInfo_orig_PartCfg(partType)
                if c and next(c) then return c end
                local fake = get_fake_badge_part_cfg()
                return fake[partType] or {}
            end
        end
        if season_year_badge_util.GetSeasonYearBadge and not season_year_badge_util._SetRoleInfo_orig_GetByUid then
            season_year_badge_util._SetRoleInfo_orig_GetByUid = season_year_badge_util.GetSeasonYearBadge
            season_year_badge_util.GetSeasonYearBadge = function(uid)
                if is_self_uid(uid) and ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                return season_year_badge_util._SetRoleInfo_orig_GetByUid(uid)
            end
        end
    end)

    pcall(function()
        local BadgeClass = require("client.slua.umg.Lobby_SeasonUI.Season2026.Item.Lobby_Season_Badge_Item_UIBP")
        if BadgeClass and BadgeClass.SetBadgeInfo and not BadgeClass._SetRoleInfo_orig_SetBadge then
            BadgeClass._SetRoleInfo_orig_SetBadge = BadgeClass.SetBadgeInfo
            BadgeClass.SetBadgeInfo = function(self, badgeData, bPlayLevelUpAni)
                local renderData = _G.SetRoleInfo_force_badge
                    or badge_for_widget_render(badgeData) or badgeData
                BadgeClass._SetRoleInfo_orig_SetBadge(self, renderData, bPlayLevelUpAni)
                if ENABLE_SEASON_YEAR_BADGE then
                    try_set_badge_center_number(self, JOURNEY_BADGE_LEVEL)
                end
            end
        end
        if BadgeClass and BadgeClass.SetBadgeGemInfo and not BadgeClass._SetRoleInfo_orig_SetGem then
            BadgeClass._SetRoleInfo_orig_SetGem = BadgeClass.SetBadgeGemInfo
            BadgeClass.SetBadgeGemInfo = function(self, gemData, newActiveGemData)
                apply_server_badge_cfg_cache()
                return BadgeClass._SetRoleInfo_orig_SetGem(self, gemData, newActiveGemData)
            end
        end
        if BadgeClass and BadgeClass.PlayBadgePartLevelUpAnimation and not BadgeClass._SetRoleInfo_orig_Anim then
            BadgeClass._SetRoleInfo_orig_Anim = BadgeClass.PlayBadgePartLevelUpAnimation
            BadgeClass.PlayBadgePartLevelUpAnimation = function(self, partType, level, bPlayAnimation)
                level = math.min(3, math.max(0, tonumber(level) or 0))
                return BadgeClass._SetRoleInfo_orig_Anim(self, partType, level, bPlayAnimation)
            end
        end
    end)

    pcall(function()
        local RoleInfoUI = require("client.slua.umg.PersonSpace.Lobby_RoleInfo_Segment180_UIBP")
        if RoleInfoUI and RoleInfoUI.OnSeasonYearBadgeUpdate and not RoleInfoUI._SetRoleInfo_wrapped_badge_ui then
            RoleInfoUI._SetRoleInfo_wrapped_badge_ui = true
            local orig = RoleInfoUI.OnSeasonYearBadgeUpdate
            RoleInfoUI.OnSeasonYearBadgeUpdate = function(self)
                apply_season_year_badge_cache()
                local renderBadge = ensure_force_badge()
                if renderBadge then
                    apply_journey_season_badge_widget(self, renderBadge)
                    if not (self.season_year_badge and self.season_year_badge.UIRoot) then
                        apply_journey_kingmark_fallback(self)
                    end
                else
                    orig(self)
                end
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.OnGetSelfRoleInfoCallBack and not RoleInfoUI._SetRoleInfo_wrapped_hist then
            RoleInfoUI._SetRoleInfo_wrapped_hist = true
            local origCb = RoleInfoUI.OnGetSelfRoleInfoCallBack
            RoleInfoUI.OnGetSelfRoleInfoCallBack = function(self, list)
                if list and list[1] then
                    apply_history_max_segment(list[1])
                    apply_profile_badge_fields(list[1])
                end
                origCb(self, list)
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.UpdateUI and not RoleInfoUI._SetRoleInfo_wrapped_updateui then
            RoleInfoUI._SetRoleInfo_wrapped_updateui = true
            local origUp = RoleInfoUI.UpdateUI
            RoleInfoUI.UpdateUI = function(self)
                origUp(self)
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.OnPostInitialize and not RoleInfoUI._SetRoleInfo_wrapped_post then
            RoleInfoUI._SetRoleInfo_wrapped_post = true
            local origPost = RoleInfoUI.OnPostInitialize
            RoleInfoUI.OnPostInitialize = function(self, ...)
                apply_season_year_badge_cache()
                origPost(self, ...)
                local function refresh()
                    apply_season_year_badge_cache()
                    force_roleinfo_profile_slots(self)
                end
                refresh()
                if self.AddTimerOnce then
                    self:AddTimerOnce(0.05, refresh)
                    self:AddTimerOnce(0.15, refresh)
                    self:AddTimerOnce(0.5, refresh)
                    self:AddTimerOnce(1.0, refresh)
                    self:AddTimerOnce(2.0, refresh)
                end
            end
        end
        if RoleInfoUI and RoleInfoUI.RefreshAceImprint and not RoleInfoUI._SetRoleInfo_wrapped_ace then
            RoleInfoUI._SetRoleInfo_wrapped_ace = true
            local origAce = RoleInfoUI.RefreshAceImprint
            RoleInfoUI.RefreshAceImprint = function(self)
                apply_ace_imprint_self()
                origAce(self)
                hide_kingmark_placeholder(self.UIRoot)
            end
        end
    end)

    pcall(function()
        local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
        if RoleInfoMainSystem and RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId
            and not RoleInfoMainSystem._SetRoleInfo_orig_hist then
            RoleInfoMainSystem._SetRoleInfo_orig_hist = RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId
            RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId = function(historyLevels, seasonTable)
                if tonumber(HISTORY_SEGMENT) and HISTORY_SEGMENT > 0 then
                    local sid = (DataMgr and DataMgr.season_id) or 0
                    if seasonTable and next(seasonTable) then
                        for z, s in pairs(seasonTable) do
                            if tonumber(s) and s > sid then sid = s end
                        end
                    end
                    return HISTORY_SEGMENT, sid
                end
                return RoleInfoMainSystem._SetRoleInfo_orig_hist(historyLevels, seasonTable)
            end
        end
    end)

    pcall(function()
        local AchUI = require("client.slua.umg.Lobby_SeasonUI.Season2026.Lobby_Season_AnnualAchievement_UIBP")
        if AchUI and AchUI.UpdateUI and not AchUI._SetRoleInfo_wrapped_update then
            AchUI._SetRoleInfo_wrapped_update = true
            local origUp = AchUI.UpdateUI
            AchUI.UpdateUI = function(self)
                apply_season_year_badge_cache()
                origUp(self)
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    local renderBadge = badge_for_widget_render(_G.SetRoleInfo_force_badge)
                    if self.CompBadge01 and self.CompBadge01.SetBadgeInfo then
                        self.CompBadge01:SetBadgeInfo(renderBadge, true)
                    end
                end
            end
        end
    end)

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        if SeasonSystem and SeasonSystem.GetBestSegment and not SeasonSystem._SetRoleInfo_orig_best then
            SeasonSystem._SetRoleInfo_orig_best = SeasonSystem.GetBestSegment
            SeasonSystem.GetBestSegment = function()
                if ENABLE_SEASON_YEAR_BADGE then
                    return CURRENT_SEGMENT
                end
                return SeasonSystem._SetRoleInfo_orig_best()
            end
        end
    end)

    pcall(function()
        local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
        if logic_leisure_season and not logic_leisure_season._SetRoleInfo_orig_GetSeg then
            logic_leisure_season._SetRoleInfo_orig_GetSeg = logic_leisure_season.GetLeisureSegmentID
            logic_leisure_season.GetLeisureSegmentID = function(self)
                return get_season_series_segment_id()
            end
            logic_leisure_season._SetRoleInfo_orig_GetSegUID = logic_leisure_season.GetLeisureSegmentIDByUID
            logic_leisure_season.GetLeisureSegmentIDByUID = function(self, uid)
                if is_self_uid(uid) then
                    return get_season_series_segment_id()
                end
                return logic_leisure_season._SetRoleInfo_orig_GetSegUID(self, uid)
            end
        end
    end)
end

-- ==================== UI事件刷新 ====================
local function post_ui_refresh_events()
    pcall(function()
        if EventSystem and EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_UPDATE_ROLEINFO then
            EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
        end
        if EventSystem and EVENTTYPE_PEAKGAME and EVENTID_PEAKGAME_RATING_NOTIFY then
            EventSystem:postEvent(EVENTTYPE_PEAKGAME, EVENTID_PEAKGAME_RATING_NOTIFY)
        end
        if EventSystem and EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
            EventSystem:postEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
        end
        if EventSystem and EVENTTYPE_LEISURE_SEASON and EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY then
            EventSystem:postEvent(EVENTTYPE_LEISURE_SEASON, EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY)
        end
        if EventSystem and EVENTTYPE_DATA_MGR and EVENTID_ACE_IMPRINT_UPDATE then
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_ACE_IMPRINT_UPDATE)
        end
    end)
end

-- ==================== 底部资料统计 ====================
local function apply_bottom_profile_stats()
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
    local uid = tonumber(DataMgr.roleData.uid)
    local ratingStr = tostring(SEASON_RATING)
    for zoneId = 1, ZONE_COUNT do
        RoleInfoSystem.CurrSeasonTPPTotalScore[zoneId] = SEASON_RATING
        RoleInfoSystem.CurrSeasonFPPTotalScore[zoneId] = SEASON_RATING
        RoleInfoSystem.CurrSeasonTPPTotalRank[zoneId] = SEASON_RANK
        RoleInfoSystem.CurrSeasonFPPTotalRank[zoneId] = SEASON_RANK
        RoleInfoSystem.PersonalTotalScoreInfo[zoneId] = { role_totalscore = ratingStr }
        RoleInfoSystem.PersonalTotalRankInfo[zoneId] = { role_totalrank = SEASON_RANK }
        RoleInfoSystem.FPPPersonalTotalScoreInfo[zoneId] = { role_totalscore = ratingStr }
        RoleInfoSystem.FPPPersonalTotalRankInfo[zoneId] = { role_totalrank = SEASON_RANK }
    end
    if RoleInfoSystem.SetElementToString then
        pcall(function()
            RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalScoreInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalRankInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.FPPPersonalTotalScoreInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.FPPPersonalTotalRankInfo)
        end)
    end
    local ok, AchieveHandler = pcall(require, "client.network.Protocol.AchieveHandler")
    if ok and AchieveHandler then
        AchieveHandler.resSummaryTb[uid] = AchieveHandler.resSummaryTb[uid] or {}
        AchieveHandler.resSummaryTb[uid].achieve_score = ACHIEVEMENT_POINTS
        AchieveHandler.resSummaryTb[uid].uid = uid
    end
    apply_data_mgr_ranks()
    apply_ace_imprint_self()
    patch_conqueror_star_ui()
    pcall(function()
        local SeasonHandler = require("client.network.Protocol.SeasonHandler")
        if tonumber(CURRENT_SEGMENT) == 801 then
            SeasonHandler.rank_rating = get_star_rating()
        end
    end)
    patch_badge_and_leisure_hooks()
    apply_season_year_badge_cache()
    apply_roleinfo_badges_ui()
    apply_personal_basic()
    apply_history_to_self_caches()
    apply_extra_settings()
    post_ui_refresh_events()
end

-- ==================== 主函数 ====================
local function apply_all()
    apply_bottom_profile_stats()
end

local function install_refresh_hooks()
    if _G.SetRoleInfo_hooks_installed then return end
    _G.SetRoleInfo_hooks_installed = true
    patch_conqueror_star_ui()
    patch_badge_and_leisure_hooks()

    pcall(function()
        if RoleInfoSystem.get_role_basic_info_rsp and not RoleInfoSystem._SetRoleInfo_wrapped then
            RoleInfoSystem._SetRoleInfo_wrapped = true
            local orig = RoleInfoSystem.get_role_basic_info_rsp
            RoleInfoSystem.get_role_basic_info_rsp = function(list)
                orig(list)
                if list and list[1] then
                    apply_profile_rank_fields(list[1])
                    apply_history_max_segment(list[1])
                    apply_profile_badge_fields(list[1])
                end
                apply_all()
            end
        end
    end)

    if Timer and Timer.New then
        if _G.SetRoleInfo_timer then
            pcall(function() _G.SetRoleInfo_timer:Stop() end)
        end
        _G.SetRoleInfo_timer = Timer.New(function()
            apply_all()
        end, 3, 0)
        _G.SetRoleInfo_timer:Start()
    end
end

-- ==================== 启动 ====================
ensure_force_badge()
pcall(apply_all)
pcall(install_refresh_hooks)

log_msg(string.format(
    "征服者 %d | 星星=%d | 积分=%d | 旅程徽章=%d | 休闲赛季段位=%d | 等级=%d",
    CURRENT_SEGMENT, CONQUEROR_STARS, get_star_rating(),
    JOURNEY_BADGE_LEVEL, get_season_series_segment_id(), PLAYER_LEVEL
))





-- ==================== 收藏等级伪造（赛季手册/收藏家系统） ====================

-- 全局伪造参数（可随时修改）
_G.FAKE_LEVEL = _G.FAKE_LEVEL or 100              -- 伪造的收藏等级
_G.FAKE_DAN = _G.FAKE_DAN or 100                  -- 伪造的段位/阶级
_G.FAKE_LEVEL_NAME = _G.FAKE_LEVEL_NAME or "Collection Champion"  -- 伪造的称号名称
_G.FAKE_SCORE = _G.FAKE_SCORE or 99999            -- 伪造的收藏积分

-- ========== 防止重复Hook的标志 ==========
if not _G.__COLLECT_FAKE_LOADED then
    _G.__COLLECT_FAKE_LOADED = true
end

-- ========== 1. Hook网络协议处理器 ==========
local function hook_collect_handler()
    local handler = package.loaded["client.network.Protocol.CollectHandler"] or package.loaded["CollectHandler"]
    if not handler and not rawget(package.loaded, "client.network.Protocol.CollectHandler") then
        pcall(require, "client.network.Protocol.CollectHandler")
    end
    
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.on_get_collect_sys_main_data_rsp and not rawget(mod, "_collection_handler_hooked") then
            rawset(mod, "_collection_handler_hooked", true)
            local orig = mod.on_get_collect_sys_main_data_rsp
            
            mod.on_get_collect_sys_main_data_rsp = function(err_code, collect_data, param)
                if collect_data and type(collect_data) == "table" then
                    rawset(collect_data, "total_score", _G.FAKE_SCORE)
                    rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
                    local ss = rawget(collect_data, "season_score")
                    if type(ss) == "table" then
                        for k in pairs(ss) do ss[k] = _G.FAKE_SCORE end
                    else
                        rawset(collect_data, "season_score", { [1] = _G.FAKE_SCORE, [2] = _G.FAKE_SCORE })
                    end
                end
                return orig(err_code, collect_data, param)
            end
            return true
        end
    end
    return false
end

-- 前置声明，避免 hook_module_manager 里访问到全局 nil
local patch_collect_module
local inject_collect_data

-- ========== 2. Hook模块管理器 ==========
local function hook_module_manager()
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig and mod.LobbyModuleConfig.collect_module and not rawget(mod, "_collection_getmodule_hooked") then
            rawset(mod, "_collection_getmodule_hooked", true)
            local orig_get = mod.GetModule
            local collect_key = mod.LobbyModuleConfig.collect_module
            
            mod.GetModule = function(self, name)
                local inst = orig_get(self, name)
                if inst and name == collect_key then
                    patch_collect_module(inst)
                    inject_collect_data()
                end
                return inst
            end
            return true
        end
    end
    return false
end

-- ========== 3. 获取收藏模块 ==========
local function get_collect_module()
    local ModuleManager = _G.ModuleManager
    if not ModuleManager then
        for _, mod in pairs(package.loaded or {}) do
            if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig and mod.LobbyModuleConfig.collect_module then
                ModuleManager = mod
                break
            end
        end
    end
    
    if ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
        local ok, cm = pcall(ModuleManager.GetModule, ModuleManager, ModuleManager.LobbyModuleConfig.collect_module)
        if ok and cm then return cm end
    end
    
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore then
            return mod
        end
    end
    return nil
end

-- ========== 4. 修补收藏模块 ==========
patch_collect_module = function(mod)
    if not mod or rawget(mod, "_collection_level_patched") then return false end
    rawset(mod, "_collection_level_patched", true)

    if mod.GetLevelDataByScore then
        rawset(mod, "GetLevelDataByScore", function(self, score, isSeason)
            return _G.FAKE_LEVEL, _G.FAKE_LEVEL_NAME, _G.FAKE_DAN
        end)
    end

    if mod.GetSeasonLevelByScore then
        rawset(mod, "GetSeasonLevelByScore", function(self, score, seasonId)
            return _G.FAKE_LEVEL, true, _G.FAKE_LEVEL_NAME
        end)
    end

    if mod.GetCollectScoreByCollectData then
        rawset(mod, "GetCollectScoreByCollectData", function(self, collect_data)
            return _G.FAKE_SCORE, _G.FAKE_SCORE
        end)
    end

    local collect_data = rawget(mod, "collect_data")
    if collect_data and type(collect_data) == "table" then
        rawset(collect_data, "total_score", _G.FAKE_SCORE)
        if not rawget(collect_data, "season_score") then rawset(collect_data, "season_score", {}) end
        local season = (rawget(mod, "GetSeasonId") and mod:GetSeasonId()) or 1
        collect_data.season_score[season] = _G.FAKE_SCORE
        rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
    end

    if rawget(mod, "OnGetMainData") or mod.OnGetMainData then
        local orig_on_get = rawget(mod, "OnGetMainData") or mod.OnGetMainData
        rawset(mod, "OnGetMainData", function(self, err_code, data, param)
            if data and type(data) == "table" then
                rawset(data, "total_score", _G.FAKE_SCORE)
                if not rawget(data, "season_score") then rawset(data, "season_score", {}) end
                local season = (rawget(self, "GetSeasonId") and self:GetSeasonId()) or 1
                if type(data.season_score) == "table" then
                    data.season_score[season] = _G.FAKE_SCORE
                end
                rawset(data, "cur_season_collect_score", _G.FAKE_SCORE)
            end
            orig_on_get(self, err_code, data, param)
        end)
    end

    return true
end

-- ========== 5. 注入数据 ==========
inject_collect_data = function()
    pcall(function()
        local cm = get_collect_module()
        if cm then
            local collect_data = rawget(cm, "collect_data")
            if collect_data and type(collect_data) == "table" then
                rawset(collect_data, "total_score", _G.FAKE_SCORE)
                if not rawget(collect_data, "season_score") then rawset(collect_data, "season_score", {}) end
                local season = (rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1
                if type(collect_data.season_score) == "table" then
                    collect_data.season_score[season] = _G.FAKE_SCORE
                end
                rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
            end
        end
    end)
    
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            if not _G.DataMgr.roleData.brief_collect_data then _G.DataMgr.roleData.brief_collect_data = {} end
            _G.DataMgr.roleData.brief_collect_data.total_score = _G.FAKE_SCORE
            _G.DataMgr.roleData.brief_collect_data.cur_season_collect_score = _G.FAKE_SCORE
        end
    end)
end

-- ========== 6. Hook收藏界面UI ==========
local function hook_collect_road_ui()
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.ShowCollect and mod.ShowSeasonCollect and not rawget(mod, "_collection_road_hooked") then
            rawset(mod, "_collection_road_hooked", true)
            local orig_show = mod.ShowCollect
            
            if orig_show then
                rawset(mod, "ShowCollect", function(self)
                    local mm = _G.ModuleManager
                    if not mm then
                        for _, m in pairs(package.loaded or {}) do
                            if type(m) == "table" and m.GetModule and m.LobbyModuleConfig then
                                mm = m
                                break
                            end
                        end
                    end
                    
                    if mm and mm.LobbyModuleConfig and mm.LobbyModuleConfig.collect_module then
                        local ok, cm = pcall(mm.GetModule, mm, mm.LobbyModuleConfig.collect_module)
                        if ok and cm and rawget(cm, "collect_data") then
                            local cd = rawget(cm, "collect_data")
                            if type(cd) == "table" then
                                rawset(cd, "total_score", _G.FAKE_SCORE)
                                if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
                                cd.season_score[(rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1] = _G.FAKE_SCORE
                                rawset(cd, "cur_season_collect_score", _G.FAKE_SCORE)
                            end
                        end
                    end
                    return orig_show(self)
                end)
            end
            return true
        end
    end
    return false
end

-- ========== 7. 一次性安装所有Hook ==========
local function install_collect_hooks()
    hook_collect_handler()
    hook_module_manager()
    hook_collect_road_ui()
    
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore and not rawget(mod, "_collection_level_patched") then
            patch_collect_module(mod)
        end
    end
    
    local cm = get_collect_module()
    if cm then
        patch_collect_module(cm)
    end
    inject_collect_data()
    
    print("[收藏伪造] Hook已安装，等级=" .. _G.FAKE_LEVEL .. " 积分=" .. _G.FAKE_SCORE)
end

-- ========== 8. 导出控制函数 ==========
_G.CollectFake = {
    Apply = function()
        install_collect_hooks()
    end,
    SetLevel = function(n)
        _G.FAKE_LEVEL = tonumber(n) or _G.FAKE_LEVEL
        install_collect_hooks()
        return _G.FAKE_LEVEL
    end,
    SetName = function(name)
        _G.FAKE_LEVEL_NAME = tostring(name) or _G.FAKE_LEVEL_NAME
    end,
    SetScore = function(n)
        _G.FAKE_SCORE = tonumber(n) or _G.FAKE_SCORE
        install_collect_hooks()
        return _G.FAKE_SCORE
    end,
    SetDan = function(n)
        _G.FAKE_DAN = tonumber(n) or _G.FAKE_DAN
    end,
}

-- ========== 9. 启动（Hook只执行一次，定时器只注入数据） ==========
if _G.Mytimer_ticker then
    -- 延迟3秒安装Hook（等游戏加载完）
    _G.Mytimer_ticker.AddTimer(3, function()
        install_collect_hooks()
    end)
    
    -- 每3秒注入一次数据（防止被游戏覆盖，但不重复Hook）
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(inject_collect_data)
    end, -1, 1)
else
    -- 没定时器就直接安装
    install_collect_hooks()
end



-- ==================== 设置界面添加武器、载具和衣服皮肤选项卡 ====================
pcall(function()
    local DazhiMH_Config = _G.DazhiMH_Config or {}
    _G.DazhiMH_Config = DazhiMH_Config

    DazhiMH_Config.PATHS = {
        "/storage/emulated/0/Android/obb/com.tencent.ig/wumingking.h",
        "/storage/emulated/0/Android/obb/com.pubg.krmobile/wumingking.h",
        "/storage/emulated/0/Android/obb/com.vng.pubgmobile/wumingking.h",
        "/storage/emulated/0/Android/obb/com.rekoo.pubgm/wumingking.h",
        "/storage/emulated/0/Android/obb/com.pubg.imobile/wumingking.h"
    }

DazhiMH_Config._activePath = nil
DazhiMH_Config._cache = DazhiMH_Config._cache or {}

    -- ==================== 衣服相关配置 ====================
    DazhiMH_Config.OUTFIT_KEYS = {
        SHIRT = true, HAIR = true, HAT = true, FACE = true, MASK = true,
        GLOVES = true, PANT = true, SHOE = true, PARACHUTE = true,
        GLIDER = true, PETSKIN = true, EXPLOSION_WEAPON = true,
        BACKPACK1 = true, BACKPACK2 = true, BACKPACK3 = true,
        BACKPACK4 = true, BACKPACK5 = true, BACKPACK6 = true,
        HELMET1 = true, HELMET2 = true, HELMET3 = true,
        HELMET4 = true, HELMET5 = true, HELMET6 = true,
        ARMOR1 = true, ARMOR2 = true, ARMOR3 = true,
        ARMOR4 = true, ARMOR5 = true, ARMOR6 = true,
    }

    DazhiMH_Config.ROLE_SKINS_MAP = {
        SHIRT = "_G.SuitSkin", HAIR = "_G.HairSkin", HAT = "_G.HatSkin",
        FACE = "_G.FaceSkin", MASK = "_G.MaskSkin", GLOVES = "_G.GlovesSkin",
        PANT = "_G.PantSkin", SHOE = "_G.ShoeSkin", PARACHUTE = "_G.ParachuteSkin",
        GLIDER = "_G.GliderSkin", PETSKIN = "_G.PetSkinMapIndex",
        BACKPACK1 = "_G.Backpack1Skin", BACKPACK2 = "_G.Backpack2Skin",
        BACKPACK3 = "_G.Backpack3Skin", BACKPACK4 = "_G.Backpack4Skin",
        BACKPACK5 = "_G.Backpack5Skin", BACKPACK6 = "_G.Backpack6Skin",
        HELMET1 = "_G.Helmet1Skin", HELMET2 = "_G.Helmet2Skin",
        HELMET3 = "_G.Helmet3Skin", HELMET4 = "_G.Helmet4Skin",
        HELMET5 = "_G.Helmet5Skin", HELMET6 = "_G.Helmet6Skin",
        ARMOR1 = "_G.Armor1Skin", ARMOR2 = "_G.Armor2Skin",
        ARMOR3 = "_G.Armor3Skin", ARMOR4 = "_G.Armor4Skin",
        ARMOR5 = "_G.Armor5Skin", ARMOR6 = "_G.Armor6Skin",
    }

    function DazhiMH_Config.FindPath()
    -- ★ 优先：按当前包名定位
    local curPath = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath()
    if curPath then
        DazhiMH_Config._activePath = curPath
        return curPath
    end

    -- ★ 回退：已缓存路径
    if DazhiMH_Config._activePath then
        local f = io.open(DazhiMH_Config._activePath, "r")
        if f then f:close(); return DazhiMH_Config._activePath end
        DazhiMH_Config._activePath = nil
    end

    -- ★ 回退：按顺序取第一个存在的
    for _, path in ipairs(DazhiMH_Config.PATHS) do
        local f = io.open(path, "r")
        if f then f:close(); DazhiMH_Config._activePath = path; return path end
    end
    return nil
end

function DazhiMH_Config.Load(force)
    if next(DazhiMH_Config._cache) then return DazhiMH_Config._cache end
    local path = DazhiMH_Config.FindPath()
        if not path then return DazhiMH_Config._cache end
        local f = io.open(path, "r")
        if not f then return DazhiMH_Config._cache end
        for line in f:lines() do
            if not line:match("^%s*#") then
                local key, value = line:match("^(%w+_?%w*)%s*=%s*(%d+)")
                if key and value then DazhiMH_Config._cache[key] = tonumber(value) end
            end
        end
        f:close()
        return DazhiMH_Config._cache
    end

    function DazhiMH_Config.Get(key, defaultValue)
        local v = DazhiMH_Config.Load()[key]
        return v ~= nil and v or (defaultValue or 1)
    end

    function DazhiMH_Config.GetMaxWeaponIndex(weaponKey)
        if _G.WeaponSkinPack and _G.WeaponSkinPack[weaponKey] then
            local maxIndex = 1
            for index in pairs(_G.WeaponSkinPack[weaponKey]) do
                if type(index) == "number" and index > maxIndex then maxIndex = index end
            end
            return maxIndex
        end
        return 20
    end

function DazhiMH_Config.GetMaxVehicleIndex(vehicleKey)
        local vehicleIdMap = {
            DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
            MIRADO = 1914, MIRADOC = 1915, ROADSTER = 19116,
            MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917,
            RONY = 1916, RZR = 1966, BIGFOOT = 1953,
            HORSE = 1987, MINIBUS = 1904, BOAT = 1910
        }
        local vehicleId = vehicleIdMap[vehicleKey]
        if vehicleId and _G.VehskinIdMappings and _G.VehskinIdMappings[vehicleId] then
            return #_G.VehskinIdMappings[vehicleId]
        end
        return 20
    end

    function DazhiMH_Config.ApplyWeaponSkin(weaponKey, index)
        index = math.floor(tonumber(index) or 1)
        if _G.WeaponNameToID and _G.WeaponSkinPack then
            local weaponID = _G.WeaponNameToID[weaponKey]
            local skinPack = _G.WeaponSkinPack[weaponKey] and _G.WeaponSkinPack[weaponKey][index]
            if weaponID and skinPack and skinPack.main then
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[weaponID] = skinPack.main
                if _G.invalidateAttachmentCache then
                    pcall(_G.invalidateAttachmentCache, skinPack.main)
                end
            end
        end
        if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
    end

function DazhiMH_Config.ApplyVehicleSkin(vehicleKey, index)
    index = math.floor(tonumber(index) or 1)
    local vehicleIdMap = {
        DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
        MIRADO = 1914, MIRADOC = 1915, ROADSTER = 19116,
        MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917,
        RONY = 1916, RZR = 1966, BIGFOOT = 1953,
        HORSE = 1987, MINIBUS = 1904, BOAT = 1910
    }
    local vehicleId = vehicleIdMap[vehicleKey]
    if vehicleId then
        _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
        -- ★★★ 记录用户最后一次真实设定的值，作为"权威"值 ★★★
        _G.__VehicleUserSet = _G.__VehicleUserSet or {}
        _G.__VehicleUserSet[vehicleId] = index
        _G.VehicleSkinIndex[vehicleId] = index
    end
    if _G.GameVehicleAvatarHandler then pcall(_G.GameVehicleAvatarHandler) end
end

    -- ==================== 衣服应用函数 ====================
function DazhiMH_Config.ApplyOutfit(key, value)
    value = math.floor(tonumber(value) or 1)
    if _G.lastConfig then _G.lastConfig[key] = value end

    local roleVar = DazhiMH_Config.ROLE_SKINS_MAP[key]
    if roleVar then
        local varName = roleVar:gsub("^_G%.", "")
        _G[varName] = value
    end

    -- ★★★ 新增：同步到 wumingking.h + 立即刷新大厅角色 ★★★
    pcall(function()
        local KEY_TO_SLOT = {
            HAIR      = 2,  HAT       = 3,  FACE  = 4,  MASK = 12,
            SHIRT     = 5,  PANT      = 6,  SHOE  = 7,  GLOVES = 16,
            PARACHUTE = 11, GLIDER    = 15,
            BACKPACK1 = 8,  BACKPACK2 = 8,  BACKPACK3 = 8,
            BACKPACK4 = 8,  BACKPACK5 = 8,  BACKPACK6 = 8,
            HELMET1   = 9,  HELMET2   = 9,  HELMET3   = 9,
            HELMET4   = 9,  HELMET5   = 9,  HELMET6   = 9,
            ARMOR1    = 10, ARMOR2    = 10, ARMOR3    = 10,
            ARMOR4    = 10, ARMOR5    = 10, ARMOR6    = 10,
        }
        local slot = KEY_TO_SLOT[key]
        if slot and _G.Wumingking and _G.Wumingking.SetSlot then
            -- 先写进 wumingking.h，避免 ApplyToLobby 里的 load() 读到旧值
            _G.Wumingking.SetSlot(slot, value)
        end
        -- 再调大厅刷新（Hook SlotSyncData + OnRep + InitDepotCommonPutOn）
        if _G.Wumingking and _G.Wumingking.ApplyToLobby then
            pcall(_G.Wumingking.ApplyToLobby)
        end
    end)

    -- 局内的 handler 保留（大厅里它们没用，进对局才生效）
    local handlers = {
        "GameAvatarHandler",
        "GameAvatarHandleroutfit",
        "GameAvatarHandlercloth",
        "GameAvatarHandlerwear",
        "RefreshAvatar",
        "GameAvatarHandlerweapons",
        "GameAvatarHandlerplayers"
    }
    for _, handlerName in ipairs(handlers) do
        if _G[handlerName] then pcall(_G[handlerName]) end
    end
end

function DazhiMH_Config.Set(key, value)
    value = tonumber(value)
    if value == nil then value = 1 end
    value = math.floor(value)

    DazhiMH_Config._cache[key] = value
    if _G.lastConfig then _G.lastConfig[key] = value end

    -- ★ 把 vehicleKeys 挪到最上面
    local vehicleKeys = {
        DACIA = true, COUPERB = true, BUGGY = true, UAZ = true,
        MIRADO = true, MIRADOC = true, ROADSTER = true, MOTO = true,
        SIDECARMOTO = true, BLOOMSC = true, RONY = true, RZR = true,
        BIGFOOT = true, HORSE = true, MINIBUS = true, BOAT = true
    }

    -- ★ 有文件就写，没文件就跳过（不再 return）
    local path = DazhiMH_Config.FindPath()
    if path then
        local lines = {}
        local f = io.open(path, "r")
        if f then
            for line in f:lines() do table.insert(lines, line) end
            f:close()
        end
        local updated = false
        for i, line in ipairs(lines) do
            if not line:match("^%s*#") then
                local k = line:match("^(%w+_?%w*)%s*=")
                if k == key then
                    lines[i] = key .. "=" .. tostring(value)
                    updated = true
                    break
                end
            end
        end
        if not updated then
            lines[#lines + 1] = key .. "=" .. tostring(value)
        end
        f = io.open(path, "w")
        if f then
            for _, line in ipairs(lines) do f:write(line, "\n") end
            f:close()
        end
    else
        print("[DazhiMH] Set: 找不到 wumingking.h，仅保存在内存: " .. key .. "=" .. value)
    end

    -- ★ 无论如何，应用一定要执行
    if key == "GRENADE_FAST_REFRESH" or key == "WEAPON_FAST_REFRESH" or key == "WEAPON_BACK_REFRESH" then
        -- 这三个是纯逻辑开关，不需要应用皮肤，直接跳过防卡顿
        -- ★ 修复：如果是修改刷新速度，必须重建定时器，否则无法生效
        if key == "WEAPON_FAST_REFRESH" then
            local interval = (value == 1) and 1.0 or 1.5
            local tx = require("common.time_ticker")
            if _G.weaponAvatarTimerIndex and tx.IsRunning(_G.weaponAvatarTimerIndex) then
                tx.RemoveTimer(_G.weaponAvatarTimerIndex)
            end
            _G.weaponAvatarTimerIndex = tx.AddTimerLoop(0, function()
                pcall(_G.GameAvatarHandlerweapons)
            end, -1, interval)
        end
    elseif vehicleKeys[key] then
        DazhiMH_Config.ApplyVehicleSkin(key, value)
    elseif DazhiMH_Config.OUTFIT_KEYS[key] then
        DazhiMH_Config.ApplyOutfit(key, value)
    else
        DazhiMH_Config.ApplyWeaponSkin(key, value)
    end

    -- ★ 同步写 wumingking.h
    if _G.Wumingking and _G.Wumingking.Save then
        pcall(_G.Wumingking.Save)
    end

    return true
end
    
    
    
    
    -- 保存自定义武器皮肤ID到文件
function DazhiMH_Config.SaveCustomWeaponSkin(weaponKey, skinId)
    skinId = math.floor(tonumber(skinId) or 0)
    if skinId > 0 then
        DazhiMH_Config.Set("CUSTOM_" .. weaponKey, skinId)
    end
end

-- 恢复所有保存的自定义武器皮肤ID
function DazhiMH_Config.RestoreCustomWeaponSkins()
    if not _G.WeaponNameToID then return end
    for weaponKey, weaponName in pairs(WeaponSettingTab.WEAPON_NAMES) do
        local savedCustomId = DazhiMH_Config.Get("CUSTOM_" .. weaponKey, 0)
        if savedCustomId > 0 then
            local weaponID = _G.WeaponNameToID[weaponKey]
            if weaponID then
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[weaponID] = savedCustomId
            end
        end
    end
end

    -- ==================== 自定义标题 ====================
    local CustomTitleLoc = {
        _patched = false,
        _nextId = 987654000,
        _map = {}
    }
function CustomTitleLoc.Patch()
    if CustomTitleLoc._patched then return end
    if not LocUtil or type(LocUtil.GetLocalizeResStr) ~= "function" then return end
    local origGetLocalizeResStr = LocUtil.GetLocalizeResStr
    LocUtil.GetLocalizeResStr = function(id)
        -- 字符串：如果是数字字符串就转数字，否则直接返回字符串本身
        if type(id) == "string" and id ~= "" then
            local num = tonumber(id)
            if not num then
                return id  -- ← 关键：字符串直接返回，不走本地化
            end
            id = num
        end
        local m = CustomTitleLoc._map
        local customText = m[id] or m[tostring(id)]
        if customText then
            return customText
        end
        return origGetLocalizeResStr(id)
    end
    CustomTitleLoc._patched = true
end

function CustomTitleLoc.Register(text)
    CustomTitleLoc.Patch()
    CustomTitleLoc._nextId = CustomTitleLoc._nextId + 1
    local id = CustomTitleLoc._nextId
    CustomTitleLoc._map[id] = text or ""
    CustomTitleLoc._map[tostring(id)] = text or ""
    return id
end

    function CustomTitleLoc.RegisterList(textList)
        local ids = {}
        for i = 1, #textList do
            ids[i] = CustomTitleLoc.Register(textList[i])
        end
        return ids
    end
    
    
    -- ==================== 数字输入弹窗核心 ====================
function DazhiMH_Config._getSkinInputPopupUI()
    if not UIManager or not UIManager.UI_Config or not UIManager.GetUI then
        return nil
    end
    return UIManager.GetUI(UIManager.UI_Config.setting_cloud_search_popups)
end

function DazhiMH_Config._confirmSkinInputPopup(ui)
    if DazhiMH_Config._skinInputConfirming then return false end

    local st = DazhiMH_Config._numInput
    ui = ui or DazhiMH_Config._getSkinInputPopupUI()
    if not st or not ui or not ui.UIRoot then return false end

    DazhiMH_Config._skinInputConfirming = true

    local text = ""
    if ui.UIRoot.EditableTextBox_PlanName then
        text = ui.UIRoot.EditableTextBox_PlanName:GetText() or ""
    end
    if text == "" and ui.currentInputCode then
        text = tostring(ui.currentInputCode)
    end

    local num = tonumber(text)
    if not num then
        DazhiMH_Config._skinInputConfirming = false
        if BattleNormalTips then
            pcall(BattleNormalTips, "请输入正确的皮肤ID", nil, 3)
        end
        return false
    end

    num = math.floor(num)
    if num < st.min then num = st.min end
    if num > st.max then num = st.max end

    if st.onConfirm then
        st.onConfirm(num)
    end

    local refreshKey = st.refreshKey
    DazhiMH_Config._numInput = nil
    DazhiMH_Config._skinPopupSetupToken = nil
    UIManager.CloseUI(UIManager.UI_Config.setting_cloud_search_popups)

    DazhiMH_Config._skinInputConfirming = false
    DazhiMH_Config._releaseSkinPopupOpeningLock()

    if refreshKey and EventSystem and EVENTTYPE_SETTING and EVENTID_SETTING_OPTION_FORCEUPDATE then
        EventSystem:postEvent(EVENTTYPE_SETTING, EVENTID_SETTING_OPTION_FORCEUPDATE, refreshKey)
    end
    return true
end

function DazhiMH_Config._setupSkinInputPopupOnce(ui)
    local st = DazhiMH_Config._numInput
    if not st or not ui or not ui.UIRoot then return false end
    if DazhiMH_Config._skinPopupSetupToken == st.token then return true end
    DazhiMH_Config._skinPopupSetupToken = st.token

    if ui.Common_Popup_Small_UIBP and ui.Common_Popup_Small_UIBP.SetData then
        ui.Common_Popup_Small_UIBP:SetData(ui, st.title)
    end
    if ui.UIRoot.EditableTextBox_PlanName then
        ui.UIRoot.EditableTextBox_PlanName:SetText(st.value)
    end
    if ui.UIRoot.EditableTextBox_Tip then
        ui.UIRoot.EditableTextBox_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if ui.UIRoot.TextBlock_CurrentPlan then
        ui.UIRoot.TextBlock_CurrentPlan:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    return true
end

function DazhiMH_Config._releaseSkinPopupOpeningLock()
    DazhiMH_Config._skinPopupOpening = false
end

function DazhiMH_Config.PatchSkinInputPopup()
    if DazhiMH_Config._skinPopupPatched then return end
    local ok, PopupClass = pcall(require, "client.slua.umg.setting.Setting_Cloud_Search_Popups_UIBP")
    if not ok or not PopupClass then return end

    local origOnInitialize = PopupClass.OnInitialize
    PopupClass.OnInitialize = function(self)
        if origOnInitialize then origOnInitialize(self) end
        if DazhiMH_Config._numInput then
            DazhiMH_Config._setupSkinInputPopupOnce(self)
        end
    end

    local origOnPostInitialize = PopupClass.OnPostInitialize
    PopupClass.OnPostInitialize = function(self)
        if origOnPostInitialize then origOnPostInitialize(self) end
        if DazhiMH_Config._numInput then
            DazhiMH_Config._setupSkinInputPopupOnce(self)
            DazhiMH_Config._releaseSkinPopupOpeningLock()
        end
    end

    local origUseClick = PopupClass.OnNewButton_UseClick
    PopupClass.OnNewButton_UseClick = function(self)
        if DazhiMH_Config._numInput and not DazhiMH_Config._skinInputConfirming then
            self:PlayAudio(sound_config.click)
            DazhiMH_Config._confirmSkinInputPopup(self)
            return
        end
        if origUseClick then return origUseClick(self) end
    end

    DazhiMH_Config._skinPopupPatched = true
end

function DazhiMH_Config.PatchShowNoticeForSkinInput()
    if DazhiMH_Config._showNoticePatched then return end

    local function wrapShowNotice(origFunc)
        return function(noticeId, bImmediately, controlTime, style)
            if DazhiMH_Config._numInput and not DazhiMH_Config._skinInputConfirming then
                local id = tonumber(noticeId)
                if id == 11474 or id == 11451 or id == 120164 then
                    DazhiMH_Config._confirmSkinInputPopup()
                    return
                end
            end
            return origFunc(noticeId, bImmediately, controlTime, style)
        end
    end

    if _G.ShowNotice then
        DazhiMH_Config._origShowNotice = DazhiMH_Config._origShowNotice or _G.ShowNotice
        _G.ShowNotice = wrapShowNotice(DazhiMH_Config._origShowNotice)
    end
    if LocUtil and LocUtil.ShowNotice then
        DazhiMH_Config._origLocUtilShowNotice = DazhiMH_Config._origLocUtilShowNotice or LocUtil.ShowNotice
        LocUtil.ShowNotice = wrapShowNotice(DazhiMH_Config._origLocUtilShowNotice)
    end

    DazhiMH_Config._showNoticePatched = true
end

function DazhiMH_Config.ShowNumberInputPopup(opts)
    opts = opts or {}
    DazhiMH_Config.PatchShowNoticeForSkinInput()
    DazhiMH_Config.PatchSkinInputPopup()

    local popupConfig = UIManager and UIManager.UI_Config and UIManager.UI_Config.setting_cloud_search_popups
    if not popupConfig then return false end

    if DazhiMH_Config._skinPopupOpening then return true end
    if UIManager.IsUIShow and UIManager.IsUIShow(popupConfig) then return true end

    DazhiMH_Config._skinPopupOpening = true
    DazhiMH_Config._skinInputConfirming = false
    DazhiMH_Config._skinPopupSetupToken = nil
    DazhiMH_Config._skinPopupOpenToken = (DazhiMH_Config._skinPopupOpenToken or 0) + 1

    DazhiMH_Config._numInput = {
        token = DazhiMH_Config._skinPopupOpenToken,
        title = opts.title or "皮肤ID",
        value = tostring(math.floor(tonumber(opts.value) or 1)),
        min = opts.min or 1,
        max = opts.max or 9999999999,
        onConfirm = opts.onConfirm,
        refreshKey = opts.refreshKey
    }

    UIManager.ShowUI(popupConfig)

    local ui = DazhiMH_Config._getSkinInputPopupUI()
    if ui and DazhiMH_Config._setupSkinInputPopupOnce(ui) then
        DazhiMH_Config._releaseSkinPopupOpeningLock()
    else
        local ok, time_ticker = pcall(require, "common.time_ticker")
        if ok and time_ticker and time_ticker.AddTimer then
            time_ticker.AddTimer(0.6, function()
                DazhiMH_Config._releaseSkinPopupOpeningLock()
            end)
        else
            DazhiMH_Config._releaseSkinPopupOpeningLock()
        end
    end
    return true
end
    
    

-- ==================== 衣服选项卡（完整版，含宠物滑块） ====================
local SuitSettingTab = _G.SuitSettingTab or {}
_G.SuitSettingTab = SuitSettingTab
SuitSettingTab.TAB_NAME = "人物套装"

-- ========== 宠物皮肤列表（用于滑块） ==========
SuitSettingTab.PET_SKIN_LIST = {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044,
    50045, -- 小兔子伙伴
50046, -- 咒骸拳击熊伙伴
}

-- 基础穿戴部位（0=恢复默认）
local BASIC_WEAR_KEYS = {
    "SHIRT", "HAIR", "HAT", "FACE", "MASK", "GLOVES", "PANT", "SHOE", "PARACHUTE", "GLIDER"
}

function SuitSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end
    DazhiMH_Config.Load(true)

    local stack = {}
    
    -- ==================== 基础穿戴 ====================
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("基础穿戴") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    for _, key in ipairs(BASIC_WEAR_KEYS) do
    for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
        if item.key == key then
            local refreshKey = item.key .. "SkinInput"
            table.insert(stack, {
                Key = refreshKey,
                UI = AliasMap.OpenWindow,
                Text = CustomTitleLoc.Register(item.label),
                GetFunc = function()
                    local val = DazhiMH_Config.Get(item.key, item.default)
                    if val == 0 then
                        return "关闭"
                    end
                    return tostring(val)
                end,
                SetFunc = function()
                    DazhiMH_Config.ShowNumberInputPopup({
                        title = item.label .. " (输入0=关闭修改)",
                        value = DazhiMH_Config.Get(item.key, item.default),
                        min = 0,
                        max = 9999999999,
                        refreshKey = refreshKey,
                        onConfirm = function(newValue)
                            newValue = math.floor(tonumber(newValue) or 0)
                            if newValue < 0 then newValue = 0 end
                            -- ★ 直接保存，0就是关闭
                            DazhiMH_Config.Set(item.key, newValue)
                            if _G.GameAvatarHandlerplayers then
                                pcall(_G.GameAvatarHandlerplayers)
                            end
                        end
                    })
                end
            })
            table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
            break
        end
    end
end
    
-- ==================== 宠物皮肤（滑块） ====================
-- Pet Skin (Slider)
table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("宠物皮肤/Pet Skin") })
table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

table.insert(stack, {
    Key = "PetSkinSlider",
    UI = AliasMap.Slider,
    Text = "宠物皮肤/Pet Skin",
    Help = "滑动切换宠物皮肤（共 " .. #SuitSettingTab.PET_SKIN_LIST .. " 种）\nSlide to switch pet skin (" .. #SuitSettingTab.PET_SKIN_LIST .. " types)",
    Min = 1,
    Max = #SuitSettingTab.PET_SKIN_LIST,
    IsPercent = false,
    GetFunc = function()
        return DazhiMH_Config.Get("PETSKIN", 1)
    end,
    SetFunc = function(_, value)
        local index = math.floor(tonumber(value) or 1)
        if index < 1 then index = 1 end
        if index > #SuitSettingTab.PET_SKIN_LIST then index = #SuitSettingTab.PET_SKIN_LIST end
        
        local petId = SuitSettingTab.PET_SKIN_LIST[index]
        
        _G.PetSkinMapIndex = index
        _G.PetSkin = petId
        
        DazhiMH_Config.Set("PETSKIN", index)
        
        if _G.HandlePetLogic then
            pcall(_G.HandlePetLogic)
        end
        if _G.ApplyPetSkinInGame then
            pcall(_G.ApplyPetSkinInGame)
        end
        
        print("[Pet] 切换到: " .. tostring(petId) .. " (索引: " .. tostring(index) .. ")")
        return true
    end
})



table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    
    -- ==================== 背包皮肤（0=不修改） ====================
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("背包皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    local backpackKeys = { "BACKPACK1", "BACKPACK2", "BACKPACK3", "BACKPACK4", "BACKPACK5", "BACKPACK6" }
    for _, key in ipairs(backpackKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = DazhiMH_Config.Get(item.key, item.default)
                        if val == 0 then return "不修改" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        DazhiMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=不修改)",
                            value = DazhiMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                DazhiMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end
    
    -- ==================== 头盔皮肤（0=不修改） ====================
    table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("头盔皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    local helmetKeys = { "HELMET1", "HELMET2", "HELMET3", "HELMET4", "HELMET5", "HELMET6" }
    for _, key in ipairs(helmetKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = DazhiMH_Config.Get(item.key, item.default)
                        if val == 0 then return "不修改" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        DazhiMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=不修改)",
                            value = DazhiMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                DazhiMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end
    
    -- ==================== 防弹衣皮肤（0=不修改） ====================
    table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("防弹衣皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    local armorKeys = { "ARMOR1", "ARMOR2", "ARMOR3", "ARMOR4", "ARMOR5", "ARMOR6" }
    for _, key in ipairs(armorKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = DazhiMH_Config.Get(item.key, item.default)
                        if val == 0 then return "不修改" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        DazhiMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=不修改)",
                            value = DazhiMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                DazhiMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end
    
    return stack
end

    -- ==================== 武器选项卡 ====================
    local WeaponSettingTab = _G.WeaponSettingTab or {}
    _G.WeaponSettingTab = WeaponSettingTab
    WeaponSettingTab.TAB_NAME = "武器皮肤"

    WeaponSettingTab.WEAPON_GROUPS = {
        {
            title = "突击步枪",
            weapons = {
                "AKM", "M16A4", "SCAR", "M416", "GROZA", "AUG", "QBZ", "M762",
                "Mk47", "G36C", "HoneyPot", "FAMAS", "ASM", "ACE32"
            }
        },
        {
            title = "冲锋枪",
            weapons = {
                "UZI", "UMP", "VECTOR", "THOMPSON", "BIZON", "MP5K", "JS9", "P90"
            }
        },
        {
            title = "狙击枪/射手步枪",
            weapons = {
                "K98", "M24", "AWM", "SKS", "VSS", "Mini14", "MK14", "Win94",
                "M1Garand", "SLR", "QBU", "Mosin", "AMR", "Mk12", "DSR"
            }
        },
        {
            title = "霰弹枪",
            weapons = {
                "S686", "S1897", "S12K", "DBS", "M1014", "NS2000"
            }
        },
        {
            title = "轻机枪",
            weapons = {
                "M249", "DP28", "MG3"
            }
        },
        {
            title = "近战武器",
            weapons = {
                "PAN", "DAGGER", "Machete"
            }
        },
    }

    WeaponSettingTab.WEAPON_NAMES = {
        AKM = "AKM", M16A4 = "M16A4", SCAR = "SCAR-L", M416 = "M416",
        GROZA = "GROZA", AUG = "AUG", QBZ = "QBZ", M762 = "M762",
        Mk47 = "Mk47", G36C = "G36C", HoneyPot = "Honey Badger",
        FAMAS = "FAMAS", ASM = "ASM", ACE32 = "ACE32",
        UZI = "UZI", UMP = "UMP45", VECTOR = "Vector", THOMPSON = "Thompson",
        BIZON = "Bizon", MP5K = "MP5K", JS9 = "JS9", P90 = "P90",
        K98 = "Kar98k", M24 = "M24", AWM = "AWM", SKS = "SKS",
        VSS = "VSS", Mini14 = "Mini14", MK14 = "MK14", Win94 = "Win94",
        M1Garand = "M1 Garand", SLR = "SLR", QBU = "QBU", Mosin = "Mosin",
        AMR = "AMR", Mk12 = "Mk12", DSR = "DSR",
        S686 = "S686", S1897 = "S1897", S12K = "S12K", DBS = "DBS",
        M1014 = "M1014", NS2000 = "NS2000",
        M249 = "M249", DP28 = "DP28", MG3 = "MG3",
        PAN = "Pan", DAGGER = "Dagger", Machete = "Machete",
    }

    function WeaponSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap or not AliasMap.Slider then return nil end
    DazhiMH_Config.Load(true)
    
    local stack = {}
    
    for _, group in ipairs(WeaponSettingTab.WEAPON_GROUPS) do
        table.insert(stack, {
            UI = AliasMap.Title,
            Text = CustomTitleLoc.Register(group.title)
        })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
        
        for _, weaponKey in ipairs(group.weapons) do
            local weaponName = WeaponSettingTab.WEAPON_NAMES[weaponKey] or weaponKey
            local maxIndex = DazhiMH_Config.GetMaxWeaponIndex(weaponKey)
            local sliderKey = "Skin_" .. weaponKey
            local inputKey = "WeaponInput_" .. weaponKey
            
            -- ========== 滑块（控制预设索引） ==========
            table.insert(stack, {
                Key = sliderKey,
                UI = AliasMap.Slider,
                Text = weaponName,
                Min = 1,
                Max = maxIndex,
                IsPercent = false,
                GetFunc = function() 
                    return DazhiMH_Config.Get(weaponKey, 1) 
                end,
                SetFunc = function(_, value)
                    value = math.floor(tonumber(value) or 1)
                    -- 使用滑块时，清除自定义ID记录
                    DazhiMH_Config.Set("CUSTOM_" .. weaponKey, 0)
                    return DazhiMH_Config.Set(weaponKey, value)
                end
            })
            
            -- ========== 输入框按钮（直接显示/修改皮肤ID） ==========
            table.insert(stack, {
                Key = inputKey,
                UI = AliasMap.OpenWindow,
                Text = "  └ 自定义皮肤ID",
                GetFunc = function()
                    -- 优先从配置文件读取保存的自定义ID
                    local savedCustomId = DazhiMH_Config.Get("CUSTOM_" .. weaponKey, 0)
                    if savedCustomId > 0 then
                        return tostring(savedCustomId)
                    end
                    -- 否则从内存中获取
                    local weaponID = _G.WeaponNameToID[weaponKey]
                    local currentSkinID = 0
                    if weaponID and _G.WeaponSkinID then
                        currentSkinID = _G.WeaponSkinID[weaponID] or 0
                    end
                    if currentSkinID == 0 then
                        return "未设置"
                    end
                    return tostring(currentSkinID)
                end,
                SetFunc = function()
                    local weaponID = _G.WeaponNameToID[weaponKey]
                    local currentSkinID = 0
                    if weaponID and _G.WeaponSkinID then
                        currentSkinID = _G.WeaponSkinID[weaponID] or 0
                    end
                    
                    DazhiMH_Config.ShowNumberInputPopup({
                        title = weaponName .. " - 输入皮肤ID",
                        value = currentSkinID,
                        min = 1,
                        max = 9999999999,
                        refreshKey = inputKey,
                        onConfirm = function(newValue)
                            local skinId = math.floor(tonumber(newValue) or 0)
                            if skinId <= 0 then return end
                            
                            -- 1. 保存皮肤ID到内存（立即生效）
                            if weaponID then
                                _G.WeaponSkinID = _G.WeaponSkinID or {}
                                _G.WeaponSkinID[weaponID] = skinId
                                if _G.GameAvatarHandlerweapons then 
                                    pcall(_G.GameAvatarHandlerweapons) 
                                end
                            end
                            
                            -- 2. 索引设为0表示使用自定义ID
                            DazhiMH_Config.Set(weaponKey, 0)
                            
                            -- 3. 永久保存自定义皮肤ID到文件
                            DazhiMH_Config.Set("CUSTOM_" .. weaponKey, skinId)
                        end
                    })
                end
            })
            
            table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
        end
        
        table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    end
    
    return stack
end

-- ==================== 载具选项卡 ====================
local VehicleSettingTab = _G.VehicleSettingTab or {}
_G.VehicleSettingTab = VehicleSettingTab
VehicleSettingTab.TAB_NAME = "载具皮肤"

VehicleSettingTab.VEHICLE_KEYS = {
    "DACIA", "COUPERB", "BUGGY", "UAZ", "MOTO", "SIDECARMOTO",
    "BLOOMSC", "RONY", "RZR", "BIGFOOT", "HORSE", "MINIBUS",
    "BOAT", "ROADSTER", "MIRADO", "MIRADOC"
}

VehicleSettingTab.VEHICLE_NAMES = {
    DACIA = "轿车 / Dacia",
    COUPERB = "双座跑车 / Coupe RB",
    BUGGY = "越野车 / Buggy",
    UAZ = "吉普车 / UAZ",
    MOTO = "摩托车 / Motorcycle",
    SIDECARMOTO = "三人摩托 / Sidecar Motorcycle",
    BLOOMSC = "踏板摩托 / Scooter",
    RONY = "罗尼皮卡 / Rony Pickup",
    RZR = "全地形车 / RZR",
    BIGFOOT = "大脚车 / Bigfoot",
    HORSE = "马 / Horse",
    MINIBUS = "巴士 / Minibus",
    BOAT = "快艇 / Boat",
    ROADSTER = "敞篷跑车 / Roadster",
    MIRADO = "Mirado / Mirado",
    MIRADOC = "Mirado敞篷 / Mirado Convertible"
}

function VehicleSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end
    DazhiMH_Config.Load(true)
    
    local stack = {}
    
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("载具皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    for _, key in ipairs(VehicleSettingTab.VEHICLE_KEYS) do
        local name = VehicleSettingTab.VEHICLE_NAMES[key] or key
        local maxIndex = DazhiMH_Config.GetMaxVehicleIndex(key)
        if maxIndex < 1 then maxIndex = 1 end
        
table.insert(stack, {
    Key = "Vehicle_" .. key,
    UI = AliasMap.Slider,
    Text = name,
    Min = 1,
    Max = maxIndex,
    IsPercent = false,
    GetFunc = function()
        -- ★ 优先读 wumingking.h
        local v
        if _G.Wumingking and _G.Wumingking.GetVehicle then
            v = _G.Wumingking.GetVehicle(key)
        end
        if not v or v < 1 then
            v = DazhiMH_Config.Get(key, 1)
        end
        v = math.floor(tonumber(v) or 1)
        if v < 1 then v = 1 end
        if v > maxIndex then v = maxIndex end
        return v
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 1)
        if idx < 1 then idx = 1 end
        if idx > maxIndex then idx = maxIndex end

        -- ★ 关键：写 wumingking.h + 实时保存
        if _G.Wumingking and _G.Wumingking.SetVehicle then
            _G.Wumingking.SetVehicle(key, idx)
        end

        -- 兼容：同时写 wumingking.h
        if DazhiMH_Config and DazhiMH_Config.Set then
            DazhiMH_Config.Set(key, idx)
        end

        -- ★ 立即刷新大厅载具
    if _G.LobbyVehicleRefresh then
        pcall(_G.LobbyVehicleRefresh)
    end

    -- ★ 立即刷新对局内载具
    if _G.GameVehicleAvatarHandler then
        pcall(_G.GameVehicleAvatarHandler)
    end
    return true
end
})
        table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
    end
    
    return stack
end





-- ==================== 功能选项卡 ====================
local BoxSettingTab = _G.BoxSettingTab or {}
_G.BoxSettingTab = BoxSettingTab
BoxSettingTab.TAB_NAME = "功能开关"
BoxSettingTab.SECTION_TITLE = "盒子皮肤"
BoxSettingTab.WEATHER_TITLE = "天气效果"
BoxSettingTab.CAMERA_TITLE = "相机设置"
BoxSettingTab.TRAIL_TITLE = "移动拖尾特效"  -- 新增
BoxSettingTab.WEATHER_OPTIONS = {
    "无天气", "下雨", "下雪", "暴风雪", "雷暴"
}
BoxSettingTab._weatherSwitcherText = nil
BoxSettingTab._trailSwitcherText = nil  -- 拖尾选项文本

BoxSettingTab.WATERMARK_TITLE = "界面水印"

function BoxSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end

    DazhiMH_Config.Load(true)
    local stack = {}

    -- ========== 盒子皮肤区域 ==========
    -- Dead Box Skin Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.SECTION_TITLE .. " / Dead Box Skin")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "DeadBoxSkinEnable",
        UI = AliasMap.Switcher,
        Text = "开启死亡盒子皮肤 / Enable Dead Box Skin",
        Help = "开启后，死亡盒子会显示为您当前使用的武器或载具皮肤效果\nWhen enabled, death box will show your current weapon or vehicle skin effect",
        GetFunc = function()
            local value = DazhiMH_Config.Get("DEADBOX_SKIN", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                _G.EnableDeadBoxSkin = true
                DazhiMH_Config.Set("DEADBOX_SKIN", 1)
            else
                _G.EnableDeadBoxSkin = false
                DazhiMH_Config.Set("DEADBOX_SKIN", 0)
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    
    -- ========== 武器检视动画区域 ==========
    -- Weapon Inspection Animation Section
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("武器检视动画 / Weapon Inspection Animation") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "WeaponAnimEnable",
        UI = AliasMap.Switcher,
        Text = "开启武器检视动画 / Enable Weapon Inspection",
        Help = "开启后，手持支持检视的武器时会自动播放检视动画\n支持升级枪械（如M416、AKM等）\nAuto-play inspection animation for supported weapons (M416, AKM, etc.)",
        GetFunc = function()
            local value = DazhiMH_Config.Get("WEAPON_ANIM", 0)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                DazhiMH_Config.Set("WEAPON_ANIM", 1)
                if _G.SetWeaponAnimation then
                    _G.SetWeaponAnimation(true)
                end
            else
                DazhiMH_Config.Set("WEAPON_ANIM", 0)
                if _G.SetWeaponAnimation then
                    _G.SetWeaponAnimation(false)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== 水印开关 ==========
    -- Watermark Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("界面水印 / Watermark")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "WatermarkEnable",
        UI = AliasMap.Switcher,
        Text = "显示频道水印 / Show Channel Watermark",
        Help = "开启后在游戏画面上方显示 @yeqizpd 水印文字\nShow @yeqizpd watermark on game screen",
        GetFunc = function()
            local value = DazhiMH_Config.Get("WATERMARK", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                DazhiMH_Config.Set("WATERMARK", 1)
                _G.WatermarkEnabled = true
            else
                DazhiMH_Config.Set("WATERMARK", 0)
                _G.WatermarkEnabled = false
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== 移动拖尾特效区域 ==========
    -- Movement Trail Effect Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.TRAIL_TITLE .. " / Movement Trail")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    -- 拖尾开关 / Trail Toggle
    table.insert(stack, {
        Key = "TrailEnable",
        UI = AliasMap.Switcher,
        Text = "开启移动拖尾特效 / Enable Movement Trail",
        Help = "开启后角色移动时显示拖尾残影特效（仅比赛对局生效）\nShow trail effect when moving (match only)",
        GetFunc = function()
            local value = DazhiMH_Config.Get("TRAIL_ENABLE", 0)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                DazhiMH_Config.Set("TRAIL_ENABLE", 1)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.Enabled = true
                    pcall(_G.GoldenLeavesTrail.Apply)
                end
            else
                DazhiMH_Config.Set("TRAIL_ENABLE", 0)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.Enabled = false
                    pcall(_G.GoldenLeavesTrail.Stop)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })

    -- 拖尾类型选择 / Trail Type Selection
    if not BoxSettingTab._trailSwitcherText then
        BoxSettingTab._trailSwitcherText = CustomTitleLoc.RegisterList({
            "浮光金叶拖尾 / Golden Leaf Trail",
            "星绘幻紫拖尾 / Star Purple Trail",
            "炫酷涂鸦足迹 / Cool Graffiti Footprint"
        })
    end

    table.insert(stack, {
        Key = "TrailType",
        UI = AliasMap.Switcher,
        Text = "拖尾类型 / Trail Type",
        Help = "选择移动时显示的拖尾特效类型\nSelect the trail effect type",
        SwitcherText = BoxSettingTab._trailSwitcherText,
        SwitcherValue = { 4531002, 4531001, 4541001 },  -- 浮光金叶, 星绘幻紫, 炫酷涂鸦足迹
        GetFunc = function()
            return DazhiMH_Config.Get("TRAIL_TYPE", 4531002)
        end,
        SetFunc = function(_, value)
            local trailId = tonumber(value) or 4531002
            DazhiMH_Config.Set("TRAIL_TYPE", trailId)
            if _G.GoldenLeavesTrail then
                _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
                if _G.GoldenLeavesTrail.Enabled then
                    pcall(_G.GoldenLeavesTrail.Apply)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== 天气区域 ==========
    -- Weather Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.WEATHER_TITLE .. " / Weather")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    if not BoxSettingTab._weatherSwitcherText then
        BoxSettingTab._weatherSwitcherText = CustomTitleLoc.RegisterList({
            "无天气 / No Weather",
            "下雨 / Rain",
            "下雪 / Snow",
            "暴风雪 / Blizzard",
            "雷暴 / Thunderstorm"
        })
    end

    table.insert(stack, {
        Key = "WeatherMode",
        UI = AliasMap.Switcher,
        Text = "天气类型 / Weather Type",
        Help = "选择对局中的天气效果\nSelect weather effect in match\n0=晴天/Sunny 1=下雨/Rain 2=下雪/Snow 3=暴风雪/Blizzard 4=雷暴/Thunderstorm",
        SwitcherText = BoxSettingTab._weatherSwitcherText,
        SwitcherValue = { 0, 1, 2, 3, 4 },
        GetFunc = function()
            return DazhiMH_Config.Get("WEATHER", 0)
        end,
        SetFunc = function(_, value)
            local weatherValue = tonumber(value) or 3
            _G.WeatherMode = weatherValue
            DazhiMH_Config.Set("WEATHER", weatherValue)
            if _G.UpdateWeatherMode then
                _G.UpdateWeatherMode(weatherValue)
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== 相机区域 ==========
    -- Camera Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.CAMERA_TITLE .. " / Camera")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    -- ★ 广角开关
    table.insert(stack, {
        Key = "FOVEnable",
        UI = AliasMap.Switcher,
        Text = "开启广角 / Enable FOV",
        Help = "开启后可以调整相机视野范围\nEnable to adjust camera field of view",
        GetFunc = function()
            local value = DazhiMH_Config.Get("FOV_ENABLE", 0)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                _G.ConfigFOVEnable = true
                DazhiMH_Config.Set("FOV_ENABLE", 1)   -- ★ 立即写 wumingking.h
            else
                _G.ConfigFOVEnable = false
                DazhiMH_Config.Set("FOV_ENABLE", 0)   -- ★ 立即写 wumingking.h
                _G.ConfigFOV = 90                      -- 关闭时回到默认 FOV
            end
            if _G.GameCameraView then pcall(_G.GameCameraView) end  -- ★ 立即生效
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    -- ★ 广角度数滑块
    table.insert(stack, {
        Key = "FOVValue",
        UI = AliasMap.Slider,
        Text = "广角度数 / FOV Value",
        Help = "调整相机视野范围 (90-120)\nAdjust camera field of view (90-120)",
        Min = 90,
        Max = 120,
        IsPercent = false,
        GetFunc = function()
            return DazhiMH_Config.Get("FOV_VALUE", 90)
        end,
        SetFunc = function(_, value)
            local fovValue = math.floor(tonumber(value) or 90)
            if fovValue < 90 then fovValue = 90 end
            if fovValue > 120 then fovValue = 120 end
            _G.ConfigFOV = fovValue
            DazhiMH_Config.Set("FOV_VALUE", fovValue)   -- ★ 立即写 wumingking.h
            if _G.GameCameraView then pcall(_G.GameCameraView) end  -- ★ 立即生效
            return true
        end
    })

    return stack
end


    -- ==================== 主选项卡管理 ====================
local function BuildSuitPage()
    local stack = SuitSettingTab.BuildStack()
    if not stack then return nil end
    return { Key = "Suit", text = "人物套装", UIKey = "Setting_StackContainer", Stack = stack }
end

local function BuildVehiclePage()
    local stack = VehicleSettingTab.BuildStack()
    if not stack then return nil end
    return { Key = "Vehicle", text = "载具皮肤", UIKey = "Setting_StackContainer", Stack = stack }
end

local function BuildBoxPage()
    local stack = BoxSettingTab.BuildStack()
    if not stack then return nil end
    return { Key = "Box", text = "功能开关", UIKey = "Setting_StackContainer", Stack = stack }
end

-- ==================== ★ 直接改写 Tab 按钮文字 ★ ====================
-- 游戏不认我们的 text 字段本地化，这里 Hook Tab 按钮的 Widget，
-- 在它 SetText/SetData 之后强制写入中文
do
local TAB_TEXT_MAP = {
    Suit    = "人物套装",
    Box     = "功能开关",
    Vehicle = "载具皮肤",
}

    -- 需要 hook 的所有可能的 Tab Widget 类名
    local WIDGET_NAMES = {
        "client.slua.umg.setting.Setting_Switch_Btn_UIBP",
        "client.slua.umg.setting.Setting_Switch_UIBP",
        "client.slua.umg.setting.Setting_SwitchItem_UIBP",
        "client.slua.umg.setting.Setting_Main_Switch_UIBP",
        "client.slua.umg.setting.Setting_Left_Menu_UIBP",
        "client.slua.umg.setting.Setting_Main_UIBP",
    }

    -- 遍历 UI 里的所有 TextBlock，找到文字是空的，尝试按索引匹配
    local function forceSetTabTextByKey(ui, key)
        if not ui or not key then return end
        local text = TAB_TEXT_MAP[key]
        if not text then return end

        -- 尝试多个可能的 TextBlock 字段名
        local cands = {
            "TextBlock_Name", "TextBlock_Title", "TextBlock_Text",
            "TextBlock_Content", "TextBlock_MenuName", "TextBlock_0",
            "TextBlock_1", "TextBlock_2", "TextBlock_3",
        }
        local root = ui.UIRoot
        if not root then return end

        for _, name in ipairs(cands) do
            local tb = root[name]
            if tb and tb.SetText then
                pcall(function() tb:SetText(text) end)
                return true
            end
        end
        return false
    end

    -- 保存 mapping：Tab键 → Widget实例。UI创建后由 OnRefresh 之类设置
    _G.__CTL_TabWidgets = _G.__CTL_TabWidgets or {}

    for _, modName in ipairs(WIDGET_NAMES) do
        pcall(function()
            local cls = require(modName)
            if not cls then return end

            -- 常见刷新函数名列表
            local funcs = {
                "SetData", "SetUIData", "RefreshData", "OnRefresh",
                "UpdateUI", "SetTabData", "Refresh", "SetInfo",
                "InitData", "SetItemData", "SetTitle",
            }
            for _, fnName in ipairs(funcs) do
                local orig = cls[fnName]
                if type(orig) == "function" and not cls["__CTL_patched_" .. fnName] then
                    cls["__CTL_patched_" .. fnName] = true
                    cls[fnName] = function(self, data, ...)
                        local ret = orig(self, data, ...)
                        pcall(function()
                            -- 尝试从 data 里拿 Key
                            local key = nil
                            if type(data) == "table" then
                                key = data.Key or data.key or data.TabKey
                            elseif type(data) == "string" then
                                key = data
                            end
                            if key and TAB_TEXT_MAP[key] then
                                forceSetTabTextByKey(self, key)
                                _G.__CTL_TabWidgets[key] = self
                            else
                                -- key 未知时，用 self.Key 或 self.key 兜底
                                local k2 = self.Key or self.key
                                if k2 and TAB_TEXT_MAP[k2] then
                                    forceSetTabTextByKey(self, k2)
                                    _G.__CTL_TabWidgets[k2] = self
                                end
                            end
                        end)
                        return ret
                    end
                end
            end

            -- 有些 Widget 用 OnPostInitialize/OnInitialize
            local postFuncs = { "OnPostInitialize", "OnInitialize", "OnShow" }
            for _, fnName in ipairs(postFuncs) do
                local orig = cls[fnName]
                if type(orig) == "function" and not cls["__CTL_patched2_" .. fnName] then
                    cls["__CTL_patched2_" .. fnName] = true
                    cls[fnName] = function(self, ...)
                        local ret = orig(self, ...)
                        pcall(function()
                            local k = self.Key or self.key or self._Key
                            if k and TAB_TEXT_MAP[k] then
                                forceSetTabTextByKey(self, k)
                                _G.__CTL_TabWidgets[k] = self
                            end
                        end)
                        return ret
                    end
                end
            end
        end)
    end

    -- 兜底：每 1 秒扫一遍 UI，看还有没有需要补文字的 Tab
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                local UIManager = _G.UIManager
                if not UIManager or not UIManager.UI_Config then return end
                -- 遍历所有已打开的 UI，尝试补文字
                for _, cfg in pairs(UIManager.UI_Config) do
                    local ok, ui = pcall(UIManager.GetUI, cfg)
                    if ok and ui and ui.UIRoot then
                        for key, text in pairs(TAB_TEXT_MAP) do
                            local w = _G.__CTL_TabWidgets[key]
                            if w and slua.isValid(w) then
                                forceSetTabTextByKey(w, key)
                            end
                        end
                    end
                end
            end)
        end, -1, 1)
    end
end
-- ==================== ★ 直接改写 Tab 按钮文字 END ★ ====================

    -- ==================== 注入主菜单 ====================
    local function InjectCatalogs(originalCatalog)
    if type(originalCatalog) ~= "table" then return originalCatalog end
for i = 1, #originalCatalog do
if originalCatalog[i] and (
    originalCatalog[i].Key == "Suit" or
    originalCatalog[i].Key == "Box" or
    originalCatalog[i].Key == "Vehicle"
) then
    return originalCatalog
end
end
local suitPage = BuildSuitPage()
local boxPage = BuildBoxPage()
local vehiclePage = BuildVehiclePage()
if not suitPage or not boxPage then
    return originalCatalog
end
local catalog = {}
for i = 1, #originalCatalog do catalog[i] = originalCatalog[i] end
catalog[#catalog + 1] = suitPage
if vehiclePage then
    catalog[#catalog + 1] = vehiclePage   -- ★ 载具放功能开关前面
end
catalog[#catalog + 1] = boxPage
return catalog
end

    local function IsSettingMainConfig(config)
        if not config then return false end
        if UIManager and UIManager.UI_Config and UIManager.UI_Config.setting_main then
            if config == UIManager.UI_Config.setting_main then return true end
        end
        return config.keyName == "setting_main"
    end

    local function IsInGameCatalog(catalog)
        if type(catalog) ~= "table" then return false end
        local hasGame, hasAccount = false, false
        for i = 1, #catalog do
            local page = catalog[i]
            if page and page.Key == "Game" then hasGame = true end
            if page and page.Key == "Account" then hasAccount = true end
        end
        return hasGame and not hasAccount
    end

    local function ShouldInject(catalog)
        if not IsInGameCatalog(catalog) then return false end
        if GameStatus and GameStatus.IsInLobbyOrMainCity then
            return not GameStatus.IsInLobbyOrMainCity()
        end
        return true
    end

    -- ... 前面所有代码 ...

    CustomTitleLoc.Patch()

    -- ========== 恢复保存的自定义武器皮肤ID ==========
    DazhiMH_Config.Load(true)
    DazhiMH_Config.RestoreCustomWeaponSkins()
    -- ===============================================

    -- 初始化弹窗
    DazhiMH_Config.PatchShowNoticeForSkinInput()
    DazhiMH_Config.PatchSkinInputPopup()



local origShowUI = UIManager and UIManager.ShowUI
if origShowUI then
    UIManager.ShowUI = function(config, arg1, arg2, arg3, arg4)
        if IsSettingMainConfig(config) and type(arg1) == "table" and ShouldInject(arg1) then
            local ok, newCatalog = pcall(InjectCatalogs, arg1)
            if ok and type(newCatalog) == "table" then
                arg1 = newCatalog
            end
        end
        if arg4 ~= nil then return origShowUI(config, arg1, arg2, arg3, arg4)
        elseif arg3 ~= nil then return origShowUI(config, arg1, arg2, arg3)
        elseif arg2 ~= nil then return origShowUI(config, arg1, arg2)
        elseif arg1 ~= nil then return origShowUI(config, arg1)
        else return origShowUI(config) end
    end
end

-- ==================== ★★★ Hook setting_main_base 写 Tab 文字 ★★★ ====================
do
    local ok, UIClass = pcall(require, "client.slua.umg.NewSetting.Main.setting_main_base")
    if ok and UIClass and UIClass.__inner_impl then
        local impl = UIClass.__inner_impl

        -- 强制给 Tab 控件写文字（自动找 TextBlock 字段）
        local function ForceSetText(child, text)
            if not child or not slua.isValid(child) then return end
            local found = false

            -- 已知可能的字段名
            local names = {
                "TextBlock_Name_U", "TextBlock_Name_S",
                "TextBlock_Name", "TextBlock_Title",
                "TextBlock_Text", "TextBlock_TabName",
                "Text_Name_U", "Text_Name_S",
            }
            for _, n in ipairs(names) do
                local tb = child[n]
                if slua.isValid(tb) and tb.SetText then
                    pcall(function() tb:SetText(text) end)
                    found = true
                end
            end

            -- 遍历 child 找所有 TextBlock / Text
            if not found then
                pcall(function()
                    for k, v in pairs(child) do
                        if type(k) == "string"
                           and (k:find("Text") or k:find("Name") or k:find("Title"))
                           and slua.isValid(v) and v.SetText then
                            v:SetText(text)
                            found = true
                        end
                    end
                end)
            end

            -- 遍历 child.UIRoot
            if not found and child.UIRoot then
                pcall(function()
                    for k, v in pairs(child.UIRoot) do
                        if type(k) == "string"
                           and (k:find("Text") or k:find("Name") or k:find("Title"))
                           and slua.isValid(v) and v.SetText then
                            v:SetText(text)
                            found = true
                        end
                    end
                end)
            end
        end

        -- 刷新所有 Tab 文字
        local function RefreshTabs(self)
            if not self or not self.UIRoot then return false end
            local list = self.AvailablePageList
            if type(list) ~= "table" or #list == 0 then return false end
            local selector = self.UIRoot.VerticalSelector_Page
            if not selector or not selector.SetNum then return false end
            pcall(function() selector:SetNum(#list) end)
            local done = 0
            for i, page in ipairs(list) do
                local text = page.text or page.Text
                if type(text) == "string" then
                    local child = selector:GetChildAt(i - 1)
                    if slua.isValid(child) then
                        ForceSetText(child, text)
                        done = done + 1
                    end
                end
            end
            if done > 0 then
                print("[DazhiMH] RefreshTabs 已刷新 " .. done .. " 个 Tab")
            end
            return done > 0
        end

        -- 确保自定义页在 AvailablePageList 里
        local function EnsureCustomPages(self)
            if not self then return end
            if type(self.AvailablePageList) ~= "table" then
                self.AvailablePageList = {}
            end
local extra = {}
local suitPage = BuildSuitPage()
local boxPage = BuildBoxPage()
local vehiclePage = BuildVehiclePage()
if suitPage then extra[#extra + 1] = suitPage end
if vehiclePage then extra[#extra + 1] = vehiclePage end   -- ★ 载具放前面
if boxPage then extra[#extra + 1] = boxPage end

            local function hasKey(key)
                for _, p in ipairs(self.AvailablePageList) do
                    if p and p.Key == key then return true end
                end
                return false
            end
            for _, p in ipairs(extra) do
                if p and not hasKey(p.Key) then
                    self.AvailablePageList[#self.AvailablePageList + 1] = p
                end
            end
        end

        -- Hook OnPostInitialize
        local origPost = impl.OnPostInitialize
        impl.OnPostInitialize = function(self)
            if origPost then origPost(self) end
            pcall(function()
                if type(self.Catalog) == "table" then
                    local ok2, newCat = pcall(InjectCatalogs, self.Catalog)
                    if ok2 and type(newCat) == "table" then
                        self.Catalog = newCat
                    end
                end
                EnsureCustomPages(self)
                RefreshTabs(self)
            end)
        end

        -- Hook OnShowFadeIn
        local origFade = impl.OnShowFadeIn
        impl.OnShowFadeIn = function(self)
            pcall(function()
                EnsureCustomPages(self)
                RefreshTabs(self)
            end)
            if origFade then return origFade(self) end
        end

        print("[DazhiMH] setting_main_base Tab Hook 已安装")
    end
end

-- ★ 功耗：0.5 → 1 秒；设置页没开直接 return
if _G.Mytimer_ticker then
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(function()
            local um = _G.UIManager
            if not um or not um.UI_Config or not um.UI_Config.setting_main then return end
            local ui = um.GetUI and um.GetUI(um.UI_Config.setting_main)
            if not ui or not ui.UIRoot then return end
            local list = ui.AvailablePageList
            if type(list) ~= "table" or #list == 0 then return end
            local selector = ui.UIRoot.VerticalSelector_Page
            if not selector or not selector.SetNum then return end
            for i, page in ipairs(list) do
                local text = page.text or page.Text
                if type(text) == "string" then
                    local child = selector:GetChildAt(i - 1)
                    if slua.isValid(child) then
                        local tbU = child.TextBlock_Name_U
                        local tbS = child.TextBlock_Name_S
                        if slua.isValid(tbU) and tbU.SetText then tbU:SetText(text) end
                        if slua.isValid(tbS) and tbS.SetText then tbS:SetText(text) end
                    end
                end
            end
        end)
    end, -1, 1)
end
-- ==================== ★★★ Tab 文字 Hook END ★★★ ====================

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(3, function() pcall(function() end) end)
        _G.Mytimer_ticker.AddTimer(8, function() pcall(function() end) end)
    end
    
    


-- ==================== 死亡盒子皮肤系统（全模式通用） ====================
local REQUIRE_UPGRADEABLE_WEAPON = false
local DEBUG_NOTICE = false

_G.TrainingDeadBox = _G.TrainingDeadBox or {}
if _G.TrainingDeadBox._timerIndex then
    pcall(function()
        require("common.time_ticker").RemoveTimer(_G.TrainingDeadBox._timerIndex)
    end)
end
_G.TrainingDeadBox._running = nil

local function notify(msg)
    if DEBUG_NOTICE then
        pcall(function()
            if ShowNotice then
                ShowNotice(tostring(msg))
            end
        end)
    end
    pcall(function() print(tostring(msg)) end)
end

_G.TrainingDeadBox._running = true
notify("盒子初始化成功")

do
    local PlayerDeadBoxPath = "/Game/BluePrints/PickUp/Special/PlayerDeadBox.PlayerDeadBox"
    local BOX_LIFE_SPAN = 20

    local timeTicker = require("common.time_ticker")
    local installed = false
    local hooksReady = false
    local lastKills = nil
    local lastHitAI = nil
    local lastHitLoc = nil
    local activeBoxes = {}
    local processedBoxes = {}  -- 用于比赛模式扫描防重复
    _G.TrainingDeadBox.activeBoxes = activeBoxes

    -- ========== 开关控制 ==========
    local function isDeadBoxSkinEnabled()
        return _G.EnableDeadBoxSkin == true or _G.EnableDeadBoxSkin == nil  -- 默认开启
    end

    -- ========== 模式判断 ==========
    local function isInTrainingMode()
        if CGameState and slua.isValid(CGameState) then
            if CGameState.bIsTrainingMode then return true end
            if CGameState.STDeadBoxClientShowFeature then return true end
        end
        local ok, gd = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and gd then
            local ok2, gs = pcall(gd.GetGameState)
            if ok2 and slua.isValid(gs) and gs.bIsTrainingMode then
                return true
            end
        end
        return false
    end

    -- 检查是否在比赛中（训练场或经典都算）
    local function isInGame()
        local ok, gd = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and gd then
            local char = gd.GetPlayerCharacter()
            if slua.isValid(char) then return true end
        end
        if slua_GameFrontendHUD then
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then return true end
        end
        return false
    end

    local function lazyGameplayData()
        local ok, mod = pcall(require, "GameLua.GameCore.Data.GameplayData")
        return ok and mod or nil
    end

    local function lazyActorTools()
        local ok, mod = pcall(require, "GameLua.Mod.BaseMod.Common.ActorTools")
        return ok and mod or nil
    end

    local function getPC()
        if slua_GameFrontendHUD then
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then return pc end
        end
        local gd = lazyGameplayData()
        if gd then
            local pc = gd.GetPlayerController()
            if slua.isValid(pc) then return pc end
        end
        return nil
    end

    local function getChar()
        local pc = getPC()
        if slua.isValid(pc) and pc.GetPlayerCharacterSafety then
            return pc:GetPlayerCharacterSafety()
        end
        local gd = lazyGameplayData()
        if gd then
            local ch = gd.GetPlayerCharacter()
            if slua.isValid(ch) then return ch end
        end
        return nil
    end

    local function getUpgradeDeadBoxPath(avatarId)
        if not avatarId or avatarId <= 0 then return nil end
        local ok, path = pcall(function()
            local ModuleManager = require("client.module_framework.ModuleManager")
            local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
            local cfg = ItemUpgradeSystem:GetUpgradeCfg(avatarId)
            if not cfg or not cfg.EffectID then return nil end
            local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", cfg.EffectID)
            if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                return effectCfg.DeadBox
            end
            return nil
        end)
        return ok and path or nil
    end

    local function getBestSkinDeadBoxPath(avatarId)
        if not avatarId or avatarId <= 0 then return nil end

        local direct = getUpgradeDeadBoxPath(avatarId)
        if direct and direct ~= "" then return direct end

        local ok, path = pcall(function()
            local ModuleManager = require("client.module_framework.ModuleManager")
            local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
            local groupList = ItemUpgradeSystem:GetUpgradeGroupByItemID(avatarId)
            if not groupList or #groupList == 0 then return nil end

            local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
            local ownedIndex = 0
            local boxPath = nil
            local boxUnlockIndex = 0

            for i, cfg in ipairs(groupList) do
                local RefitID = ItemUpgradeSystem:GetRefitSwitcherID(cfg.ItemID)
                if wardrobe_data:GetHallDepotItemDataByResID(cfg.ItemID)
                        or wardrobe_data:GetHallDepotItemDataByResID(RefitID) then
                    if i > ownedIndex then ownedIndex = i end
                end
                if boxUnlockIndex == 0 then
                    local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", cfg.EffectID)
                    if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                        boxUnlockIndex = i
                        boxPath = effectCfg.DeadBox
                    end
                end
            end

            if ownedIndex > 0 and boxUnlockIndex > 0 and ownedIndex >= boxUnlockIndex and boxPath then
                return boxPath
            end

            for i = #groupList, 1, -1 do
                local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", groupList[i].EffectID)
                if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                    if groupList[i].ItemID == avatarId then
                        return effectCfg.DeadBox
                    end
                end
            end
            return nil
        end)
        return ok and path or nil
    end

    local function hasPlayerDeadBoxAvatarPath(avatarId)
        if not avatarId or avatarId <= 0 then return false end
        local ok, exists = pcall(function()
            local UAvatarUtils = import("AvatarUtils")
            local UBackpackUtils = import("BackpackUtils")
            local avatarPath = UAvatarUtils.GetWeaponAvatarDeadBoxAvatarHandlePath(avatarId)
            return UBackpackUtils.IsBattleItemHandlePathExist(avatarPath)
        end)
        return ok and exists == true
    end

    local function getCurrentWeaponAvatarId()
        local char = getChar()
        if not slua.isValid(char) then return 0 end
        local weapon = char:GetCurrentWeapon()
        if not slua.isValid(weapon) then return 0 end
        local defineId = weapon:GetItemDefineID()
        if not defineId or defineId.Type == 6 then return 0 end
        local baseWeaponId = defineId.TypeSpecificID
        local skinId = 0

        pcall(function()
            local comp = weapon.WeaponAvatarComponent
            if slua.isValid(comp) then
                local EWeaponAttachmentSocketType = import("EWeaponAttachmentSocketType")
                local skinDefine = comp:GetEquippedItemDefineID(EWeaponAttachmentSocketType.MasterGun)
                if skinDefine and skinDefine.TypeSpecificID and skinDefine.TypeSpecificID > 0
                        and skinDefine.TypeSpecificID ~= baseWeaponId then
                    skinId = skinDefine.TypeSpecificID
                end
            end
        end)

        if skinId <= 0 and _G.WeaponSkinID and _G.WeaponSkinID[baseWeaponId] and _G.WeaponSkinID[baseWeaponId] > 0 then
            skinId = _G.WeaponSkinID[baseWeaponId]
        end

        if skinId <= 0 then
            local pc = getPC()
            if slua.isValid(pc) and pc.GetWeaponAvatarItemId then
                pcall(function()
                    local UBackpackUtils = import("BackpackUtils")
                    local bpId = UBackpackUtils.GetBPIDByResID(baseWeaponId)
                    local av = pc:GetWeaponAvatarItemId(bpId)
                    if av and av > 0 then skinId = av end
                end)
            end
        end

        return skinId or 0
    end

    local function resolveSpawnLoc(uPawn, fallbackLoc)
        if slua.isValid(uPawn) then
            if uPawn.GetRandomPutDownLocation then
                local ok, loc = pcall(uPawn.GetRandomPutDownLocation, uPawn, 80)
                if ok and loc then return loc end
            end
            local ok, loc = pcall(uPawn.K2_GetActorLocation, uPawn)
            if ok and loc then return loc end
        end
        return fallbackLoc
    end

    local function resolveAvatarId(avatarId)
        if not avatarId or avatarId <= 0 then
            avatarId = getCurrentWeaponAvatarId()
        end
        if REQUIRE_UPGRADEABLE_WEAPON then
            local function isUpgradeableSkin(id)
                if _G.isUpgradeableWeaponSkin then
                    local ok, r = pcall(_G.isUpgradeableWeaponSkin, id)
                    if ok and r then return true end
                end
                return false
            end
            if not isUpgradeableSkin(avatarId) then
                return nil
            end
        end
        return avatarId or 0
    end

    local function activateBoxVisuals(uBoxActor, feature)
        local delayFn = feature and feature.AddGameTimer
        local run = function()
            if not slua.isValid(uBoxActor) then return end
            pcall(function()
                if uBoxActor.Survive_FMC_Chest1 then
                    uBoxActor.Survive_FMC_Chest1:SetHiddenInGame(false, false)
                end
                if uBoxActor.DeadParticleSystem then
                    uBoxActor.DeadParticleSystem:Activate(true)
                end
            end)
        end
        if delayFn then
            pcall(delayFn, feature, 1, false, run)
        else
            timeTicker.AddTimer(1, run)
        end
    end

    local function spawnActorAtPath(boxPath, loc, onReady)
        local playerChar = getChar()
        local ActorTools = lazyActorTools()
        if ActorTools and slua.isValid(playerChar) then
            local called = false
            local function wrap(uBoxActor)
                if called then return end
                called = true
                onReady(uBoxActor)
            end
            local ok = pcall(function()
                ActorTools.SpawnActorAsync(playerChar, boxPath, loc, FRotator(0, 0, 0), FVector(1, 1, 1), wrap)
            end)
            if ok then
                timeTicker.AddTimer(0.8, function()
                    if not called then wrap(nil) end
                end)
                return true
            end
        end
        local syncOk, syncBox = pcall(function()
            local asset_util = require("common.asset_util")
            local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
            if not slua.isValid(world) then return nil end
            local cls = asset_util.GetAssetSync(boxPath)
            if not cls then return nil end
            return world:SpawnActor(cls, loc, FRotator(0, 0, 0), nil)
        end)
        if syncOk and slua.isValid(syncBox) then
            onReady(syncBox)
            return true
        end
        onReady(nil)
        return false
    end

    local function applySkinDeadBoxEffects(uBoxActor)
        if not slua.isValid(uBoxActor) then return end
        pcall(function()
            if uBoxActor.PlaySmokeAnim then
                uBoxActor:PlaySmokeAnim()
            end
        end)
        pcall(function()
            if uBoxActor.DeadParticleSystem then
                uBoxActor.DeadParticleSystem:Activate(true)
            end
        end)
        pcall(function()
            local DeadBoxAvatarComp = uBoxActor.DeadBoxAvatarComponent_BP
            if slua.isValid(DeadBoxAvatarComp) and DeadBoxAvatarComp.HandleOnItemHandleLoaded then
                DeadBoxAvatarComp:HandleOnItemHandleLoaded()
            end
        end)
    end

    local function spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, onDone)
        if not hasPlayerDeadBoxAvatarPath(useAvatarId) then
            onDone(false)
            return
        end
        spawnActorAtPath(PlayerDeadBoxPath .. "_C", loc, function(uBoxActor)
            if not slua.isValid(uBoxActor) then
                onDone(false)
                return
            end
            trackBox(uBoxActor)
            pcall(function() uBoxActor:SetLifeSpan(boxLife) end)
            pcall(function()
                uBoxActor:SetAvatarId(useAvatarId)
                uBoxActor:OnRep_AvatarId()
            end)
            applySkinDeadBoxEffects(uBoxActor)
            activateBoxVisuals(uBoxActor, feature)
            onDone(true, "player")
        end)
    end

    local function spawnSkinMeshDeadBox(loc, skinBoxPath, feature, boxLife, onDone)
        spawnActorAtPath(skinBoxPath, loc, function(uBoxActor)
            if not slua.isValid(uBoxActor) then
                onDone(false)
                return
            end
            trackBox(uBoxActor)
            pcall(function() uBoxActor:SetLifeSpan(boxLife) end)
            applySkinDeadBoxEffects(uBoxActor)
            activateBoxVisuals(uBoxActor, feature)
            onDone(true, "skin")
        end)
    end

    local lastSpawnAt = 0

    local function spawnDeadBoxAt(loc, avatarId, feature)
        -- ========== 开关检查 ==========
        if not isDeadBoxSkinEnabled() then return false end
        -- ==============================

        if not loc then return false end
        if not isInGame() then return false end  -- 改为 isInGame()，训练场和比赛都生效

        local now = os.clock()
        if now - lastSpawnAt < 0.5 then return false end
        lastSpawnAt = now

        local useAvatarId = resolveAvatarId(avatarId)
        if useAvatarId == nil then
            return false
        end

        local skinBoxPath = getBestSkinDeadBoxPath(useAvatarId)

        local boxLife = (feature and feature.BoxLifeSpan) or BOX_LIFE_SPAN

        local function done(ok, kind)
            if ok then
            else
            end
        end

        if skinBoxPath then
            spawnSkinMeshDeadBox(loc, skinBoxPath, feature, boxLife, function(ok, kind)
                if ok then
                    done(true, kind)
                    return
                end
                spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, function(ok2, kind2)
                    done(ok2, kind2)
                end)
            end)
            return true
        end

        spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, function(ok, kind)
            done(ok, kind)
        end)
        return true
    end

    -- ========== 训练场模式：基于事件触发 ==========
    local function onKillDetected()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end  -- 训练场专用

        local loc = nil
        if slua.isValid(lastHitAI) then
            loc = resolveSpawnLoc(lastHitAI, lastHitLoc)
        end
        if not loc and lastHitLoc then
            loc = lastHitLoc
        end
        if not loc then
            local char = getChar()
            if slua.isValid(char) then
                local ok, charLoc = pcall(char.K2_GetActorLocation, char)
                if ok and charLoc then
                    loc = FVector(charLoc.X + 150, charLoc.Y, charLoc.Z)
                end
            end
        end
        local feature = CGameState and CGameState.STDeadBoxClientShowFeature
        spawnDeadBoxAt(loc, nil, feature)
        lastHitAI = nil
    end

    local function onLocalShootDamage(_, __, weapon, targetActor, damage, hitBodyType, impactPoint)
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        if not slua.isValid(targetActor) then return end
        local isAI = false
        pcall(function() isAI = Game and Game.IsAI and Game:IsAI(targetActor) end)
        if not isAI then return end
        lastHitAI = targetActor
        if impactPoint then
            lastHitLoc = impactPoint
        else
            pcall(function() lastHitLoc = targetActor:K2_GetActorLocation() end)
        end
    end

    local function onKillNumChanged()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        if CGameState and CGameState.STDeadBoxClientShowFeature and CGameState.STDeadBoxClientShowFeature._tdbHooked then
            return
        end
        onKillDetected()
    end

    local function onPawnDied(_, __, uPawn, uKiller, typeId)
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        local myChar = getChar()
        if not slua.isValid(myChar) or uKiller ~= myChar then return end
        local isAI = false
        pcall(function() isAI = Game and Game.IsAI and Game:IsAI(uPawn) end)
        if not isAI then return end
        lastHitAI = uPawn
        onKillDetected()
    end

    -- ========== 比赛模式：扫描场景中已有的盒子 ==========
    local function scanAndModifyExistingBoxes()
        if not isDeadBoxSkinEnabled() then return end
        if isInTrainingMode() then return end  -- 训练场用事件触发，不扫描

        pcall(function()
            local pc = getPC()
            if not slua.isValid(pc) then return end

            local pk = pc.Playerkey or pc.PlayerKey
            if not pk then return end

            local UGameplayStatics = import("GameplayStatics")
            if not UGameplayStatics then return end

            local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
            if not slua.isValid(world) then return end

            local APlayerTombBox = import("PlayerTombBox")
            if not APlayerTombBox then return end

            local actors = UGameplayStatics.GetAllActorsOfClass(world, APlayerTombBox, {})
            if not actors then return end

            for _, actor in pairs(actors) do
                if slua.isValid(actor) then
                    -- 跳过已处理的
                    if not processedBoxes[actor] then
                        local causer = actor.DamageCauser
                        if causer and (causer.Playerkey == pk or causer.PlayerKey == pk) then
                            local avatarComp = actor.DeadBoxAvatarComponent_BP
                            if slua.isValid(avatarComp) then
                                local skinId = getCurrentWeaponAvatarId()
                                if skinId > 0 and hasPlayerDeadBoxAvatarPath(skinId) then
                                    pcall(function()
                                        actor:SetAvatarId(skinId)
                                        actor:OnRep_AvatarId()
                                        applySkinDeadBoxEffects(actor)
                                        processedBoxes[actor] = true
                                        notify("DeadBox skin applied: " .. tostring(skinId))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function pollKills()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end

        if CGameState and CGameState.STDeadBoxClientShowFeature and CGameState.STDeadBoxClientShowFeature._tdbHooked then
            return
        end
        local gd = lazyGameplayData()
        if not gd then return end
        local ps = gd.GetPlayerState()
        if not slua.isValid(ps) or ps.Kills == nil then return end

        if lastKills ~= nil and ps.Kills > lastKills then
            onKillDetected()
        end
        lastKills = ps.Kills
    end

    local function hookCleanAIDeadBox(feature)
        if not feature or feature._tdbCleanHooked then return end
        feature.CleanAIDeadBox = function(self)
            local ActorTools = lazyActorTools()
            if not ActorTools or not slua.isValid(CGameState) then return end
            local uActorArray = ActorTools.GetAllActors(CGameState, "PlayerTombBox")
            local kept, removed = 0, 0
            for _, uActor in pairs(uActorArray) do
                if uActor and slua.isValid(uActor) then
                    if isOurBox(uActor) then
                        kept = kept + 1
                    else
                        pcall(function() Game:RemoveActor(uActor) end)
                        removed = removed + 1
                    end
                end
            end
            if DEBUG_NOTICE then notify("TDB clean k=" .. kept .. " r=" .. removed) end
        end
        feature._tdbCleanHooked = true
    end

    local function hookSpawnSTDeadBox(feature)
        if not feature or feature._tdbHooked then return end
        feature.SpawnSTDeadBox = function(self, loc, avatarId)
            if not loc then return end
            if self.IsAuthority and self:IsAuthority() then return end
            spawnDeadBoxAt(loc, avatarId, self)
        end
        feature._tdbHooked = true
    end

    local function hookPlayerController(pc)
        if not slua.isValid(pc) or pc._tdbHooked then return end
        if pc.ClientRPC_SpawnDeadBox then
            pc.ClientRPC_SpawnDeadBox = function(self, loc, avatarId)
                local feature = CGameState and CGameState.STDeadBoxClientShowFeature
                spawnDeadBoxAt(loc, avatarId, feature)
            end
        end
        pc._tdbHooked = true
    end

    local function registerEvents()
        if installed then return end
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_LOCAL_HANDLE_SHOOT_DAMAGE, onLocalShootDamage)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_ON_KILLNUM_CHANGED, onKillNumChanged)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_PAWN_DIED, onPawnDied)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_CONTROLLER_BEGINPLAY, function()
                timeTicker.AddTimer(1, function()
                    _G.TrainingDeadBox.tryInstall()
                end)
            end)
        end)
        installed = true
    end

    function _G.TrainingDeadBox.tryInstall()
        registerEvents()
        if CGameState and CGameState.STDeadBoxClientShowFeature then
            hookCleanAIDeadBox(CGameState.STDeadBoxClientShowFeature)
            hookSpawnSTDeadBox(CGameState.STDeadBoxClientShowFeature)
        end
        local pc = getPC()
        if slua.isValid(pc) then
            hookPlayerController(pc)
        end
        if isInGame() and not hooksReady then
            hooksReady = true
        end
    end

    function _G.TrainingDeadBox.tick()
        if not slua_GameFrontendHUD then return end
        if not isDeadBoxSkinEnabled() then return end

        _G.TrainingDeadBox.tryInstall()

        -- 训练场：用击杀轮询
        if isInTrainingMode() then
            pollKills()
        else
            -- 比赛模式：扫描已有盒子
            scanAndModifyExistingBoxes()
        end
    end

    registerEvents()
    timeTicker.AddTimer(0.5, function() _G.TrainingDeadBox.tryInstall() end)

    if _G.TrainingDeadBox._timerIndex and timeTicker.IsRunning(_G.TrainingDeadBox._timerIndex) then
        timeTicker.RemoveTimer(_G.TrainingDeadBox._timerIndex)
    end
    _G.TrainingDeadBox._timerIndex = timeTicker.AddTimerLoop(0.3, function()
        _G.TrainingDeadBox.tick()
    end, -1, 1.0)

end
end)


--天气

pcall(function()
    local game_frontend_hud = require("game_frontend_hud")
    local audio_util = require("client.common.audio_util")
    local AkGameplayStatics = import("AkGameplayStatics")
    local EScreenParticleEffectType = import("EScreenParticleEffectType")

    -- ===================== 从全局配置读取 =====================
    local function getWeatherModeFromGlobal()
        local modeNum = _G.WeatherMode or 3  -- 默认暴风雪
        if modeNum == 0 then return "none"
        elseif modeNum == 1 then return "rain"
        elseif modeNum == 2 then return "snow"
        elseif modeNum == 3 then return "blizzard"
        elseif modeNum == 4 then return "storm"
        else return "blizzard"
        end
    end

    local WEATHER_MODE = getWeatherModeFromGlobal()
    local ENABLED = true  -- 启用天气系统

    -- ===================== AUDIO PATHS =====================
    local AUDIO_RAIN_AMBIENT_PLAY = "/Game/WwiseEvent/Ambient/Play_Ambient_Rain.Play_Ambient_Rain"
    local AUDIO_RAIN_AMBIENT_STOP = "/Game/WwiseEvent/Ambient/Play_Ambient_Rain_Stop.Play_Ambient_Rain_Stop"
    local AUDIO_RAIN_LOOP_PLAY    = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Play_PlanPH_Object_Rain_Loop.Play_PlanPH_Object_Rain_Loop"
    local AUDIO_RAIN_LOOP_STOP    = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Stop_PlanPH_Object_Rain_Loop.Stop_PlanPH_Object_Rain_Loop"
    local AUDIO_SNOW_PLAY = "/Game/Mod/IceWorld3/WwiseEvent/IceWorld3_Treasure_350/Play_IceWorld3_TreasureBox_Snow_Loop.Play_IceWorld3_TreasureBox_Snow_Loop"
    local AUDIO_SNOW_STOP = "/Game/Mod/IceWorld3/WwiseEvent/IceWorld3_Treasure_350/Stop_IceWorld3_TreasureBox_Snow_Loop.Stop_IceWorld3_TreasureBox_Snow_Loop"
    local AUDIO_WIND_PLAY  = "/Game/Mod/EasternRealm/WwiseEvent/EasternRealm_POI_Wind_360/Play_EasternRealm_Wind_Guest_Loop.Play_EasternRealm_Wind_Guest_Loop"
    local AUDIO_WIND_STOP  = "/Game/Mod/EasternRealm/WwiseEvent/EasternRealm_POI_Wind_360/Stop_EasternRealm_Wind_Guest_Loop.Stop_EasternRealm_Wind_Guest_Loop"
    local AUDIO_WIND2_PLAY = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Play_PlanPH_Object_Wind_Machine_Loop.Play_PlanPH_Object_Wind_Machine_Loop"
    local AUDIO_WIND2_STOP = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Stop_PlanPH_Object_Wind_Machine_Loop.Stop_PlanPH_Object_Wind_Machine_Loop"
    local AUDIO_WIND3_PLAY = "/Game/Mod/Mecha/WwiseEvent/Mecha_FlyArmor_320/Play_Mecha_FlyArmor_Wind_Loop.Play_Mecha_FlyArmor_Wind_Loop"
    local AUDIO_THUNDER_PLAY = "/Game/WwiseEvent/Character_KillEffect/Character_KillEffect_320/Play_Character_KillEffect_Thunder_320.Play_Character_KillEffect_Thunder_320"
    local AUDIO_THUNDER_STOP = "/Game/WwiseEvent/Character_KillEffect/Character_KillEffect_320/Stop_Character_KillEffect_Thunder_2D_320.Stop_Character_KillEffect_Thunder_2D_320"
    local AUDIO_THUNDER2_PLAY = "/Game/Mod/ZNQ8th/WwiseEvent/ZNQ8th_RegionalTransformation_430/Play_ZNQ8th_RegionalTransformation_ThunderCloud.Play_ZNQ8th_RegionalTransformation_ThunderCloud"
    local AUDIO_THUNDER3_PLAY = "/Game/Mod/GoldenDragon/WwiseEvent/GoldenDragon_300/Play_GoldenDragon_Ground_Thunder.Play_GoldenDragon_Ground_Thunder"

    local THUNDER_MIN_FRAMES = 480
    local THUNDER_MAX_FRAMES = 1200
    local SOUND_REFRESH_FRAMES = 600

    -- ===================== STATE =====================
    local _active = false
    local _loopAudioIDs = {}
    local _lastInGame = false
    local _frameCount = 0
    local _lastSoundRefresh = 0
    local _nextThunderFrame = 0
    local _thunderIndex = 1

    local ALL_STOP_PATHS = {
        AUDIO_RAIN_AMBIENT_STOP, AUDIO_RAIN_LOOP_STOP,
        AUDIO_SNOW_STOP, AUDIO_WIND_STOP, AUDIO_WIND2_STOP,
        AUDIO_THUNDER_STOP,
    }

    local THUNDER_PATHS = {
        AUDIO_THUNDER_PLAY,
        AUDIO_THUNDER2_PLAY,
        AUDIO_THUNDER3_PLAY,
    }

    -- ===================== HELPERS =====================
    local function IsInGame()
        if GameStatus and GameStatus.IsInFightingStatus then
            return GameStatus.IsInFightingStatus()
        end
        if Client and GameFrontendHUD then
            return Client.GetUnrealNetworkStatus(GameFrontendHUD) == "Online"
        end
        return false
    end

    local function GetPlayerCharacter()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return nil end
        if pc.GetPlayerCharacterSafety then return pc:GetPlayerCharacterSafety() end
        if pc.GetCurPlayerCharacter then return pc:GetCurPlayerCharacter() end
        return nil
    end

    local function StopAudioID(id)
        if id and id ~= 0 then
            pcall(function() audio_util.StopSound(id) end)
            pcall(function() AkGameplayStatics.StopPlayingID(id) end)
        end
    end

    local function PlayLoopSound(key, path)
        local ownerObj = GetPlayerCharacter()
        pcall(function()
            audio_util.PlayAudioAsync(path, ownerObj, nil, function(soundId)
                if soundId and soundId ~= 0 then
                    _loopAudioIDs[key] = soundId
                end
            end)
        end)
    end

    local function StopAllLoopSounds()
        for key, id in pairs(_loopAudioIDs) do
            StopAudioID(id)
            _loopAudioIDs[key] = nil
        end
        pcall(function()
            for _, stopPath in ipairs(ALL_STOP_PATHS) do
                audio_util.PlayAudioAsync(stopPath)
            end
            AkGameplayStatics.AkSetRTPCValue("Ambient_Weather", 0, false)
        end)
    end

    local function ScheduleNextThunder()
        _nextThunderFrame = _frameCount + math.random(THUNDER_MIN_FRAMES, THUNDER_MAX_FRAMES)
    end

    local function PlayThunder()
        local ownerObj = GetPlayerCharacter()
        local path = THUNDER_PATHS[_thunderIndex]
        _thunderIndex = (_thunderIndex % #THUNDER_PATHS) + 1
        pcall(function()
            audio_util.PlayAudioAsync(path, ownerObj)
        end)
        ScheduleNextThunder()
    end

    local function NeedsRainSound()
        return WEATHER_MODE == "rain" or WEATHER_MODE == "storm"
    end

    local function NeedsSnowSound()
        return WEATHER_MODE == "snow" or WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function NeedsWindSound()
        return WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function NeedsThunder()
        return WEATHER_MODE == "rain" or WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function StartSounds()
        StopAllLoopSounds()
        local ownerObj = GetPlayerCharacter()

        if NeedsRainSound() then
            pcall(function()
                AkGameplayStatics.AkSetRTPCValue("Ambient_Weather", 100, false)
            end)
            PlayLoopSound("rain_ambient", AUDIO_RAIN_AMBIENT_PLAY)
            PlayLoopSound("rain_loop", AUDIO_RAIN_LOOP_PLAY)
        end

        if NeedsSnowSound() then
            PlayLoopSound("snow", AUDIO_SNOW_PLAY)
        end

        if NeedsWindSound() then
            PlayLoopSound("wind1", AUDIO_WIND_PLAY)
            PlayLoopSound("wind2", AUDIO_WIND2_PLAY)
            PlayLoopSound("wind3", AUDIO_WIND3_PLAY)
        end

        if NeedsThunder() then
            ScheduleNextThunder()
            PlayThunder()
        end

        _lastSoundRefresh = _frameCount
    end

    -- ===================== VISUAL EFFECTS =====================
    local function SetRainVisual(on)
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.SetIsRainy then
            pc:SetIsRainy(on)
        end
    end

    local function SetParticleEffect(effectType, on)
        local char = GetPlayerCharacter()
        if slua.isValid(char) and char.SetRainyEffectEnable then
            char:SetRainyEffectEnable(effectType, on, on and 500 or 0)
        end
    end

    local function SetSnowScreenUI(on)
        pcall(function()
            if not UIManager or not UIManager.UI_Config_InGame then return end
            local cfg = UIManager.UI_Config_InGame.SnowEffectUI
            if not cfg then return end
            if on then
                if not UIManager.IsUIShow(cfg) then UIManager.ShowUI(cfg) end
            elseif UIManager.IsUIShow(cfg) then
                UIManager.CloseUI(cfg)
            end
        end)
    end

    local function ApplyVisuals(on)
        if not on then
            SetRainVisual(false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Rainy, false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Snowy, false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Blizzard, false)
            SetSnowScreenUI(false)
            return
        end

        local showRain     = WEATHER_MODE == "rain" or WEATHER_MODE == "storm"
        local showSnow     = WEATHER_MODE == "snow" or WEATHER_MODE == "storm"
        local showBlizzard = WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"

        SetRainVisual(showRain)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Rainy, showRain)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Snowy, showSnow or showBlizzard)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Blizzard, showBlizzard)
        SetSnowScreenUI(showSnow or showBlizzard)
    end

    -- ===================== ENABLE / DISABLE =====================
    local function EnableWeather()
        if _active then return end
        if not IsInGame() or WEATHER_MODE == "none" then return end
        ApplyVisuals(true)
        StartSounds()
        _active = true
        print("[DEV_WEATHER] Enabled | mode =", WEATHER_MODE)
    end

    local function DisableWeather()
        if not _active then return end
        ApplyVisuals(false)
        StopAllLoopSounds()
        _active = false
        _nextThunderFrame = 0
        print("[DEV_WEATHER] Disabled")
    end

    local function RefreshWeather()
        if not ENABLED or not _active or WEATHER_MODE == "none" then return end
        ApplyVisuals(true)
        if _frameCount - _lastSoundRefresh >= SOUND_REFRESH_FRAMES then
            StartSounds()
        end
    end

    -- ===================== 更新天气模式（供外部调用） =====================
    function _G.UpdateWeatherMode(modeNum)
        local newMode = "none"
        if modeNum == 0 then newMode = "none"
        elseif modeNum == 1 then newMode = "rain"
        elseif modeNum == 2 then newMode = "snow"
        elseif modeNum == 3 then newMode = "blizzard"
        elseif modeNum == 4 then newMode = "storm"
        else newMode = "blizzard"
        end
        
        if WEATHER_MODE ~= newMode then
            local wasActive = _active
            if wasActive then
                DisableWeather()
            end
            WEATHER_MODE = newMode
            if wasActive and newMode ~= "none" and IsInGame() then
                EnableWeather()
            end
            print("[DEV_WEATHER] Mode changed to: " .. tostring(newMode) .. " (value=" .. tostring(modeNum) .. ")")
        else
            WEATHER_MODE = newMode
        end
    end

    -- ===================== MAIN LOOP =====================
    local function OnTick()
        if not ENABLED or WEATHER_MODE == "none" then return end

        _frameCount = _frameCount + 1
        local inGame = IsInGame()

        if inGame and not _lastInGame then
            print("[DEV_WEATHER] Entered match")
            EnableWeather()
        elseif not inGame and _lastInGame then
            print("[DEV_WEATHER] Left match")
            DisableWeather()
        end

        if inGame and _active then
            if _frameCount % 120 == 0 then
                RefreshWeather()
            end

            if NeedsThunder() and _nextThunderFrame > 0 and _frameCount >= _nextThunderFrame then
                PlayThunder()
            end
        end

        _lastInGame = inGame
    end

    game_frontend_hud.SetSluaTickListener(OnTick)

    game_frontend_hud.SetPostSwitchGameStatusListener(function(status)
        print("[DEV_WEATHER] Status:", status)
        if IsInGame() then EnableWeather() else DisableWeather() end
    end)

    print("[DEV_WEATHER] Loaded | mode = " .. WEATHER_MODE .. " (configurable via WEATHER= value)")
end)









-- ==================== Phoenixtra Summon (机甲召唤修复/解锁) ====================
if not _G.__PHOENIXTRA_SUMMON_LOADED__ then
    _G.__PHOENIXTRA_SUMMON_LOADED__ = true
    
    local PhoenixtraSummon = {}
    
    -- ========== 配置参数（可修改） ==========
    -- 机甲/金甲物品ID（优先从配置文件 SHIRT=xxx 读取，此值为默认值）
    PhoenixtraSummon.XSUIT_ID = 1407856
    -- 机甲周期/等级档位（6代表6星/7星档位）
    PhoenixtraSummon.PERIOD = 6
    -- 备用模板ID（当主ID无配置时使用此ID的召唤特效）
    PhoenixtraSummon.FALLBACK_TEMPLATE_ID = 1407841
    -- 召唤动作ID（用于预下载资源）
    PhoenixtraSummon.CALL_ACTION_ID = 12219843
    -- 自定义召唤雕像序列路径（nil表示自动从配置读取）
    PhoenixtraSummon.CALL_STATUE_SEQ = nil
    -- 召唤动画播放时长（秒）
    PhoenixtraSummon.CALL_TIME = 7
    
    -- ========== 功能开关 ==========
    -- 绕过7星检查（允许无7星机甲也能召唤）
    PhoenixtraSummon.BYPASS_7STAR_CHECK = true
    -- 强制在对局中穿戴机甲
    PhoenixtraSummon.FORCE_WEAR_IN_MATCH = true
    -- 本地播放召唤序列（即使服务器验证失败也播动画）
    PhoenixtraSummon.PLAY_LOCAL_SEQUENCE = true
    -- 调试日志开关
    PhoenixtraSummon.DEBUG = true
    -- 自动安装开关
    PhoenixtraSummon.AUTO_INSTALL = true
    
    -- ========== 内部变量 ==========
    PhoenixtraSummon._dataHooked = false
    PhoenixtraSummon._menuHooked = false
    PhoenixtraSummon._platformHooked = false
    PhoenixtraSummon._tipsHooked = false
    PhoenixtraSummon._gameTipsHooked = false
    PhoenixtraSummon._resolvedEffect = nil
    PhoenixtraSummon._origGetTableData = nil
    PhoenixtraSummon._origGetTable = nil
    PhoenixtraSummon._origRequire = nil
    PhoenixtraSummon._lastSummonParam = nil
    PhoenixtraSummon._eventsHooked = false
    PhoenixtraSummon._summonCooldownUntil = 0
    PhoenixtraSummon._lastInstallState = nil
    
    local PLATFORM_MODULE = "GameLua.Activity.Commercialize.Actor.InteractActor.XSuitPlatform"
    
    -- ========== 从配置文件更新机甲ID ==========
function PhoenixtraSummon.UpdateFromConfig()
    -- ★ 彻底废弃，绝不锁模型
    return 0
end
    
    local function hasMethod(obj, name)
        if not obj then return false end
        local v = obj[name]
        if v == nil then return false end
        local t = type(v)
        return t == "function" or t == "userdata" or t == "table"
    end
    
    local function getOwnerName(owner)
        local ok, name = pcall(function()
            local KismetSystemLibrary = import("KismetSystemLibrary")
            return KismetSystemLibrary.GetObjectName(owner)
        end)
        if ok and name then
            return tostring(name)
        end
        return tostring(owner)
    end
    
    local function isReadyState()
        local gs = slua_GameFrontendHUD and slua_GameFrontendHUD.GetGameState and slua_GameFrontendHUD:GetGameState()
        if slua.isValid(gs) and gs.GetGameModeState then
            return gs:GetGameModeState() == "ReadyState"
        end
        return false
    end
    
    local function log(msg)
        if PhoenixtraSummon.DEBUG then
            print("[PhoenixtraSummon] " .. tostring(msg))
        end
        pcall(function()
            local f = io.open("data/share1/loglua.txt", "a+")
            if f then
                f:write(os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
                f:close()
            end
        end)
    end
    
    local function safeRequire(path)
        local ok, mod = pcall(require, path)
        if ok then return mod end
        return nil
    end
    
    local function shallowCopy(src)
        if type(src) ~= "table" then return src end
        local dst = {}
        for k, v in pairs(src) do dst[k] = v end
        return dst
    end
    
    local function rawGetTableData(tableName, key)
        if PhoenixtraSummon._origGetTableData then
            return PhoenixtraSummon._origGetTableData(tableName, key)
        end
        if CDataTable and CDataTable.GetTableData then
            return CDataTable.GetTableData(tableName, key)
        end
        return nil
    end
    
    local function rawGetTable(tableName)
        if PhoenixtraSummon._origGetTable then
            return PhoenixtraSummon._origGetTable(tableName)
        end
        if CDataTable and CDataTable.GetTable then
            return CDataTable.GetTable(tableName)
        end
        return nil
    end
    
    local function readBattleEffect(itemID)
        itemID = tonumber(itemID)
        if not itemID or itemID <= 0 then return nil end
        local row = rawGetTableData("GoldClothBattleEffect", itemID)
        if row and row.CallStatue and row.CallStatue ~= "" then
            return row
        end
        return nil
    end
    
    function PhoenixtraSummon.ResolveEffectConfig()
        if PhoenixtraSummon._resolvedEffect then
            return PhoenixtraSummon._resolvedEffect
        end
        local native = readBattleEffect(PhoenixtraSummon.XSUIT_ID)
        if native then
            PhoenixtraSummon._resolvedEffect = shallowCopy(native)
            PhoenixtraSummon._resolvedEffect.ID = PhoenixtraSummon.XSUIT_ID
            log("native CallStatue ok for " .. tostring(PhoenixtraSummon.XSUIT_ID))
            return PhoenixtraSummon._resolvedEffect
        end
        local template = readBattleEffect(PhoenixtraSummon.FALLBACK_TEMPLATE_ID)
        if not template then
            local tbl = rawGetTable("GoldClothBattleEffect")
            if tbl then
                for _, row in pairs(tbl) do
                    if row and row.CallStatue and row.CallStatue ~= "" then
                        template = row
                        break
                    end
                end
            end
        end
        PhoenixtraSummon._resolvedEffect = template and shallowCopy(template) or {}
        PhoenixtraSummon._resolvedEffect.ID = PhoenixtraSummon.XSUIT_ID
        PhoenixtraSummon._resolvedEffect.Level = 7
        PhoenixtraSummon._resolvedEffect.CallTime = PhoenixtraSummon._resolvedEffect.CallTime or PhoenixtraSummon.CALL_TIME
        if PhoenixtraSummon.CALL_STATUE_SEQ and PhoenixtraSummon.CALL_STATUE_SEQ ~= "" then
            PhoenixtraSummon._resolvedEffect.CallStatue = PhoenixtraSummon.CALL_STATUE_SEQ
        end
        log("CallStatue=" .. tostring(PhoenixtraSummon._resolvedEffect.CallStatue or ""))
        return PhoenixtraSummon._resolvedEffect
    end
    
    function PhoenixtraSummon.BuildInjectedBattleEffectRow(existing)
        local cfg = PhoenixtraSummon.ResolveEffectConfig()
        local row = shallowCopy(existing or cfg)
        row.ID = PhoenixtraSummon.XSUIT_ID
        row.Level = 7
        row.CallStatue = cfg.CallStatue or row.CallStatue or ""
        row.CallTime = cfg.CallTime or row.CallTime or PhoenixtraSummon.CALL_TIME
        return row
    end
    
    function PhoenixtraSummon.InstallDataTableHooks()
        if PhoenixtraSummon._dataHooked or not CDataTable or not CDataTable.GetTableData then
            return PhoenixtraSummon._dataHooked
        end
        PhoenixtraSummon._origGetTableData = CDataTable.GetTableData
        PhoenixtraSummon._origGetTable = CDataTable.GetTable
        function CDataTable.GetTableData(tableName, key, ...)
            local row = PhoenixtraSummon._origGetTableData(tableName, key, ...)
            if tableName == "GoldClothBattleEffect" and tonumber(key) == PhoenixtraSummon.XSUIT_ID then
                return PhoenixtraSummon.BuildInjectedBattleEffectRow(row)
            end
            return row
        end
        PhoenixtraSummon._dataHooked = true
        log("CDataTable hooked")
        return true
    end
    
    function PhoenixtraSummon.RegisterLogicXSuitItem()
        local LogicXSuit = safeRequire("client.slua.logic.XSuit.logic_xsuit")
        if not LogicXSuit then return false end
        pcall(function()
            if LogicXSuit.InitXSuitItemList and not LogicXSuit.bItemInfoInited then
                LogicXSuit.InitXSuitItemList()
            end
        end)
        LogicXSuit.itemInfoList = LogicXSuit.itemInfoList or {}
        -- 注册机甲物品信息（周期=6，等级=7星）
        LogicXSuit.itemInfoList[PhoenixtraSummon.XSUIT_ID] = {period = PhoenixtraSummon.PERIOD, level = 7}
        LogicXSuit.bItemInfoInited = true
        log("LogicXSuit registered for ID " .. tostring(PhoenixtraSummon.XSUIT_ID))
        return true
    end
    
    function PhoenixtraSummon.IsXSuitPlatformActor(owner)
        if not owner or not slua.isValid(owner) then return false end
        -- 检查是否是机甲召唤平台Actor
        if hasMethod(owner, "TriggerCallShowSequence") and hasMethod(owner, "GetStatue") then
            return true
        end
        if hasMethod(owner, "Wearing7StarXSuit") and hasMethod(owner, "TrySetCurrentCaller") then
            return true
        end
        local name = getOwnerName(owner):lower()
        if name:find("xsuitplatform") or name:find("xsuit_platform") or name:find("goldsuitplatform") then
            return true
        end
        return false
    end
    
    function PhoenixtraSummon.ForceWearNow()
        -- 强制当前角色穿戴机甲（用于跳过检测）
        return true
    end
    
    function PhoenixtraSummon.BlockTip49553(tipsID)
        -- 阻止"需要7星机甲"的提示（tipsID=49553）
        return PhoenixtraSummon.BYPASS_7STAR_CHECK and tonumber(tipsID) == 49553
    end
    
    function PhoenixtraSummon.InstallTipsHooks()
        -- Hook提示系统，屏蔽7星检查提示
        if not PhoenixtraSummon._tipsHooked then
            local tips = safeRequire("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
            if tips and type(tips.BattleNormalTipsByTextID) == "function" and not tips.__phoenixtra_patched then
                local orig = tips.BattleNormalTipsByTextID
                tips.BattleNormalTipsByTextID = function(tipsID, ...)
                    if PhoenixtraSummon.BlockTip49553(tipsID) then
                        log("blocked BattleNormalTips 49553")
                        return
                    end
                    return orig(tipsID, ...)
                end
                tips.__phoenixtra_patched = true
                PhoenixtraSummon._tipsHooked = true
                log("IngameTipsTools hooked")
            end
        end
        if not PhoenixtraSummon._gameTipsHooked and Game and type(Game.UIShowTips) == "function" and not Game.__phoenixtra_patched then
            local orig = Game.UIShowTips
            Game.UIShowTips = function(self, playerKey, textID, ...)
                if PhoenixtraSummon.BlockTip49553(textID) then
                    log("blocked Game:UIShowTips 49553")
                    return
                end
                return orig(self, playerKey, textID, ...)
            end
            Game.__phoenixtra_patched = true
            PhoenixtraSummon._gameTipsHooked = true
            log("Game:UIShowTips hooked")
        end
    end
    
    function PhoenixtraSummon.PatchPlatformInstance(actor)
        -- 修补单个召唤平台实例
        if not actor or actor.__phoenixtra_inst_patched then return false end
        if not PhoenixtraSummon.IsXSuitPlatformActor(actor) then return false end
        
        local origClick = actor.OnClientClickInteractiveButton
        actor.OnClientClickInteractiveButton = function(self, character, component)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                PhoenixtraSummon.ForceWearNow()
                return true
            end
            if origClick then return origClick(self, character, component) end
            return true
        end
        
        if hasMethod(actor, "Wearing7StarXSuit") then
            actor.Wearing7StarXSuit = function(self, character)
                if PhoenixtraSummon.BYPASS_7STAR_CHECK then return true end
                return false
            end
        end
        
        if hasMethod(actor, "GetWearingXSuitID") then
            actor.GetWearingXSuitID = function(self, character)
                PhoenixtraSummon.ForceWearNow()
                return PhoenixtraSummon.XSUIT_ID
            end
        end
        
        actor.__phoenixtra_inst_patched = true
        log("patched live platform " .. getOwnerName(actor))
        return true
    end
    
    function PhoenixtraSummon.PatchLivePlatformActors()
        -- 扫描场景中所有召唤平台并修补
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD.GetWorld and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return 0 end
        local count = 0
        pcall(function()
            local ActorTools = safeRequire("GameLua.Mod.BaseMod.Common.ActorTools")
            if not ActorTools or not ActorTools.GetAllActorsWithTag then return end
            local tags = {"XSuitPlatform", "GoldSuitPlatform", "SummonPlatform"}
            for _, tag in ipairs(tags) do
                local arr = ActorTools.GetAllActorsWithTag(world, tag)
                if arr then
                    for _, actor in pairs(arr) do
                        if PhoenixtraSummon.PatchPlatformInstance(actor) then
                            count = count + 1
                        end
                    end
                end
            end
        end)
        if count > 0 then log("PatchLivePlatformActors count=" .. tostring(count)) end
        return count
    end
    
    function PhoenixtraSummon.FindPlatformModule()
        local cls = safeRequire(PLATFORM_MODULE)
        if cls then return cls end
        if package and package.loaded then
            for name, mod in pairs(package.loaded) do
                if type(name) == "string" and name:find("XSuitPlatform", 1, true) and type(mod) == "table" then
                    return mod
                end
            end
        end
        return nil
    end
    
    function PhoenixtraSummon.PatchXSuitPlatformImpl(impl)
        -- 修补召唤平台类的实现
        if type(impl) ~= "table" or impl.__phoenixtra_patched then return false end
        
        local origGetWear = impl.GetWearingXSuitID
        local origGetStatue = impl.GetStatue
        local origWear = impl.Wearing7StarXSuit
        local origClientClick = impl.OnClientClickInteractiveButton
        
        impl.GetWearingXSuitID = function(self, character)
            if PhoenixtraSummon.FORCE_WEAR_IN_MATCH then
                PhoenixtraSummon.ForceWearNow()
                return PhoenixtraSummon.XSUIT_ID
            end
            if origGetWear then return origGetWear(self, character) end
            return 0
        end
        
        impl.GetStatue = function(self, suitID)
            if tonumber(suitID) == PhoenixtraSummon.XSUIT_ID then
                local cfg = PhoenixtraSummon.ResolveEffectConfig()
                return cfg.CallStatue or ""
            end
            if origGetStatue then return origGetStatue(self, suitID) end
            return ""
        end
        
        impl.Wearing7StarXSuit = function(self, character)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                local cfg = PhoenixtraSummon.ResolveEffectConfig()
                if cfg.CallStatue and cfg.CallStatue ~= "" then return true end
                return true
            end
            if origWear then return origWear(self, character) end
            return false
        end
        
        impl.OnClientClickInteractiveButton = function(self, character, component)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                PhoenixtraSummon.ForceWearNow()
                return true
            end
            if origClientClick then return origClientClick(self, character, component) end
            return true
        end
        
        impl.__phoenixtra_patched = true
        log("XSuitPlatform impl patched")
        return true
    end
    
    function PhoenixtraSummon.InstallPlatformHooks()
        if PhoenixtraSummon._platformHooked then
            PhoenixtraSummon.PatchLivePlatformActors()
            return true
        end
        local cls = PhoenixtraSummon.FindPlatformModule()
        if not cls then
            PhoenixtraSummon.PatchLivePlatformActors()
            return false
        end
        local impl = cls.__inner_impl or cls
        local ok = PhoenixtraSummon.PatchXSuitPlatformImpl(impl)
        if cls ~= impl then
            ok = PhoenixtraSummon.PatchXSuitPlatformImpl(cls) or ok
        end
        if ok then PhoenixtraSummon._platformHooked = true end
        PhoenixtraSummon.PatchLivePlatformActors()
        return PhoenixtraSummon._platformHooked
    end
    
    function PhoenixtraSummon.PatchBasicSkillsMenuTable(BP)
        -- 修补技能菜单，拦截召唤按钮点击
        if not BP or type(BP.Action_InteractiveComponent) ~= "function" then return false end
        if BP.__phoenixtra_patched then return true end
        
        local orig = BP.Action_InteractiveComponent
        BP.Action_InteractiveComponent = function(self, Param, ExtraParam)
            local Component = Param and Param.Component
            PhoenixtraSummon._lastSummonParam = {Component = Component, Param = Param, ExtraParam = ExtraParam}
            
            if PhoenixtraSummon.BYPASS_7STAR_CHECK and Component and Component.GetOwner then
                local owner = Component:GetOwner()
                if slua.isValid(owner) and PhoenixtraSummon.IsXSuitPlatformActor(owner) then
                    log("Action_InteractiveComponent bypass summon")
                    PhoenixtraSummon.ForceWearNow()
                    if PhoenixtraSummon.PLAY_LOCAL_SEQUENCE then
                        local cfg = PhoenixtraSummon.ResolveEffectConfig()
                        if cfg.CallStatue and cfg.CallStatue ~= "" and hasMethod(owner, "TriggerCallShowSequence") then
                            pcall(function() owner:TriggerCallShowSequence(cfg.CallStatue) end)
                        end
                    end
                    if self.HideNormalBtn then
                        pcall(function() self:HideNormalBtn("Type_InteractiveComponent", Param) end)
                    end
                    return
                end
            end
            
            return orig(self, Param, ExtraParam)
        end
        
        BP.__phoenixtra_patched = true
        log("BasicSkillsMenu Action_InteractiveComponent hooked")
        return true
    end
    
    function PhoenixtraSummon.InstallBasicSkillsMenuHook()
        safeRequire("GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Actions")
        local BP = safeRequire("GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Config")
        if not BP then return false end
        if not PhoenixtraSummon.PatchBasicSkillsMenuTable(BP) then return false end
        PhoenixtraSummon._menuHooked = true
        return true
    end
    
    function PhoenixtraSummon.InstallMatchEvents()
        -- 监听对局状态，ReadyState时刷新平台修补
        if PhoenixtraSummon._eventsHooked then return end
        if type(EventSystem) ~= "table" or not EventSystem.AddCommonEvent then return end
        pcall(function()
            EventSystem:AddCommonEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, function(_, _, state)
                if state == "ReadyState" then
                    PhoenixtraSummon.PatchLivePlatformActors()
                    PhoenixtraSummon.ForceWearNow()
                    log("ReadyState refresh platform")
                end
            end)
            PhoenixtraSummon._eventsHooked = true
            log("match events hooked")
        end)
    end
    
    function PhoenixtraSummon.InstallRequireHook()
        -- Hook require，在模块加载时自动安装对应补丁
        if PhoenixtraSummon._origRequire then return end
        PhoenixtraSummon._origRequire = require
        _G.require = function(modname)
            local result = PhoenixtraSummon._origRequire(modname)
            if modname == "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools" then
                PhoenixtraSummon.InstallTipsHooks()
            elseif modname == "GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Actions" then
                PhoenixtraSummon.InstallBasicSkillsMenuHook()
            elseif modname == PLATFORM_MODULE then
                PhoenixtraSummon.InstallPlatformHooks()
            end
            return result
        end
        log("require hook installed")
    end
    
    function PhoenixtraSummon.PreloadAssets()
        -- 预下载机甲相关资源
        local cfg = PhoenixtraSummon.ResolveEffectConfig()
        local PufferConst = safeRequire("client.slua.logic.download.puffer_const")
        local PufferManager = safeRequire("client.slua.logic.download.puffer.puffer_manager")
        if not PufferConst or not PufferManager then return end
        local list = {PhoenixtraSummon.XSUIT_ID, PhoenixtraSummon.FALLBACK_TEMPLATE_ID, PhoenixtraSummon.CALL_ACTION_ID}
        if cfg.CallStatue and cfg.CallStatue ~= "" then
            table.insert(list, cfg.CallStatue)
        end
        pcall(function()
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, list)
        end)
    end
    
    function PhoenixtraSummon.Install()
        -- 主安装函数：依次安装所有补丁
        PhoenixtraSummon.UpdateFromConfig()           -- 先从配置读取机甲ID
        PhoenixtraSummon.InstallTipsHooks()
        PhoenixtraSummon.InstallRequireHook()
        PhoenixtraSummon.InstallDataTableHooks()
        PhoenixtraSummon.ResolveEffectConfig()
        PhoenixtraSummon.RegisterLogicXSuitItem()
        PhoenixtraSummon.InstallPlatformHooks()
        PhoenixtraSummon.InstallBasicSkillsMenuHook()
        PhoenixtraSummon.InstallMatchEvents()
        PhoenixtraSummon.PreloadAssets()
        PhoenixtraSummon.ForceWearNow()
        log("Install done with XSUIT_ID=" .. tostring(PhoenixtraSummon.XSUIT_ID))
        return true
    end
    
    -- ========== 定时器安装 ==========
    if PhoenixtraSummon.AUTO_INSTALL then
        if _G.Mytimer_ticker then
            -- 延迟2秒安装（等待配置文件读取）
            _G.Mytimer_ticker.AddTimer(2, function()
                pcall(function() PhoenixtraSummon.Install() end)
            end)
            -- 持续更新机甲ID（当配置文件热更新时）
            _G.Mytimer_ticker.AddTimerLoop(2, function()
                pcall(function()
                    if PhoenixtraSummon.UpdateFromConfig then
                        local newID = PhoenixtraSummon.UpdateFromConfig()
                        if newID then
                            -- ID变化时重新安装
                            if PhoenixtraSummon.XSUIT_ID ~= newID then
                                PhoenixtraSummon._resolvedEffect = nil
                                PhoenixtraSummon.Install()
                            end
                        end
                    end
                    if not PhoenixtraSummon._platformHooked then
                        PhoenixtraSummon.InstallPlatformHooks()
                    end
                    PhoenixtraSummon.ForceWearNow()
                end)
            end, -1, 1)
        else
            -- 无定时器时直接安装
            pcall(function() PhoenixtraSummon.Install() end)
        end
    end
    
    _G.PhoenixtraSummon = PhoenixtraSummon
end



-- ==================== 武器动画模块（DIY检视动画） ====================
-- 基于 WeaponCheckSkill 配置自动播放武器专属动画
-- 需要在游戏中手持支持该功能的武器（如部分升级枪械）

if not _G.WeaponAnimationModule then
    _G.WeaponAnimationModule = {}
    
    local WAM = _G.WeaponAnimationModule
    
    -- ========== 配置 ==========
WAM.LOOP = true           -- 是否循环播放
WAM.TOTAL_SEC = 60        -- 总播放时长（秒），LOOP=true时生效
WAM.AUTO_START = false    -- 是否自动启动（默认关闭）
WAM.DEBUG = false         -- 调试日志
    
    -- ========== 新增：配置文件开关支持 ==========
    -- 从配置文件读取开关状态 (WEAPON_ANIM=1开启 / 0关闭)
local function IsWeaponAnimEnabled()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("WEAPON_ANIM", 0)  -- 默认 0=关闭
    end
    return configValue == 1
end
    
    -- 更新开关状态
    WAM._enabled = IsWeaponAnimEnabled()
    
    -- 外部控制函数
    function WAM.SetEnabled(enabled)
        WAM._enabled = enabled == true
        WAM.AUTO_START = WAM._enabled
        if not WAM._enabled then
            WAM.Stop()
        else
            WAM.Start()
        end
        -- 保存到配置文件
        if _G.DazhiMH_Config and _G.DazhiMH_Config.Set then
            _G.DazhiMH_Config.Set("WEAPON_ANIM", WAM._enabled and 1 or 0)
        end
        print("[WeaponAnim] 开关状态: " .. tostring(WAM._enabled))
    end
    
    function WAM.IsEnabled()
        return WAM._enabled
    end
    
    -- ========== 原代码继续 ==========
    
    -- 内部变量
    WAM._running = false
    WAM._lastSeqActor = nil
    WAM._timer = nil
    WAM._currentChar = nil
    WAM._seqPath = nil
    WAM._actorPath = nil
    WAM._duration = 0
    WAM._origLoc = nil
    WAM._origRot = nil
    
    -- 默认序列Actor路径（备选）
    local DEFAULT_ACTOR = "/Game/Mod/EvoBase/BluePrints/Actor/BP_CharacterLevelSequenceActor.BP_CharacterLevelSequenceActor_C"
    
    -- 日志函数
    local function log(msg)
        if WAM.DEBUG then
            print("[WeaponAnim] " .. tostring(msg))
        end
    end
    
    -- 获取当前角色
    function WAM.GetCharacter()
        local ok, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or not GameplayData then return nil end
        return GameplayData.GetPlayerCharacter()
    end
    
    -- 检查角色是否站立且可用
    function WAM.IsCharacterReady(char)
        if not char or not slua.isValid(char) then return false end
        local ok, EP = pcall(import, "EPawnState")
        if not ok then return false end
        
        local isStanding = (char.CurrentStates == (1 << EP.Stand))
        if isStanding and char.IsHandleInFold and char:IsHandleInFold() then
            isStanding = false
        end
        
        local inVehicle = char:HasState(EP.InVehicle) or char:HasState(EP.DriveVehicle)
        local isDead = char:HasState(EP.Save) or char:HasState(EP.Pick)
        
        return isStanding and not inVehicle and not isDead
    end
    
    -- 获取武器Avatar组件
    function WAM.GetWeaponAvatarComponent(char)
        if not char or not slua.isValid(char) then return nil end
        local weapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
        if slua.isValid(weapon) and slua.isValid(weapon.WeaponAvatarComponent) then
            return weapon.WeaponAvatarComponent
        end
        return nil
    end
    
    -- 软对象转路径
    local function softToString(softObj)
        local result = nil
        pcall(function()
            if not softObj then return end
            if softObj.ToSoftObjectPath then
                local sp = softObj:ToSoftObjectPath()
                if sp and sp.ToString then result = sp:ToString() end
                if (not result) and sp and sp.GetAssetPathString then
                    result = sp:GetAssetPathString()
                end
            end
            if (not result) and softObj.ToString then
                result = softObj:ToString()
            end
        end)
        return result
    end
    
    -- 解析武器的检视动画配置
    function WAM.ResolveAnimationConfig(char)
        local seqPath, actorPath, duration = nil, nil, 0
        
        pcall(function()
            local wac = WAM.GetWeaponAvatarComponent(char)
            if not wac then return end
            
            local ES = import("EWeaponAttachmentSocketType")
            local ET = import("ECharSpecialLevelSequenceType")
            local handle = wac:GetEquippedHandle(ES.MasterGun)
            
            if handle and slua.isValid(handle) and handle.WeaponSpecialLevelSequenceList then
                for _, seq in pairs(handle.WeaponSpecialLevelSequenceList) do
                    if seq.LevelSequenceType == ET.ECharSpecLvSeq_WeaponCheck and seq.LevelSequenceConfig then
                        local cfg = seq.LevelSequenceConfig
                        seqPath = softToString(cfg.LevelSequence)
                        actorPath = softToString(cfg.SequenceActorTemplate)
                        duration = cfg.LevelSequenceDuration or 0
                        break
                    end
                end
            end
            
            if not actorPath or actorPath == "" then
                local AU = import("AvatarUtils")
                local ES2 = import("EWeaponAttachmentSocketType")
                local skinID = wac:GetEquippedItemDefineID(ES2.MasterGun).TypeSpecificID
                if skinID <= 0 then
                    local weapon = char:GetCurrentWeapon()
                    if weapon then
                        skinID = weapon:GetItemDefineID().TypeSpecificID
                    end
                end
                local base = AU.GetWeaponAvatarParentID(AU.GetBPIDByResID(skinID), false)
                local data = CDataTable.GetTableData("WeaponCheckSkill", base)
                if data and data.SequenceActorPath and data.SequenceActorPath ~= "" then
                    actorPath = data.SequenceActorPath
                end
            end
        end)
        
        if not actorPath or actorPath == "" then
            actorPath = DEFAULT_ACTOR
        end
        
        return seqPath, actorPath, duration
    end
    
    -- 播放一次检视动画
    function WAM.PlayOnce(char)
        if not WAM._seqPath or WAM._seqPath == "" then
            log("No sequence path available")
            return false
        end
        
        local ok = false
        pcall(function()
            local UKismetMathLibrary = import("KismetMathLibrary")
            local transform = UKismetMathLibrary.MakeTransform(
                WAM._origLoc or char:K2_GetActorLocation(),
                WAM._origRot or char:K2_GetActorRotation(),
                FVector(1, 1, 1)
            )
            
            local seqActor = Game:PlayLevelSequence(
                char, WAM._seqPath, transform, 
                WAM._actorPath or DEFAULT_ACTOR, 
                false, nil, char
            )
            
            if slua.isValid(seqActor) then
                if seqActor.SetCharacterAndPlay then
                    seqActor:SetCharacterAndPlay(char)
                end
                char.CurrentLevelSequence = seqActor
                WAM._lastSeqActor = seqActor
                ok = true
                log("Sequence played successfully")
            end
        end)
        
        return ok
    end
    
    -- 检查序列是否存活
    function WAM.IsSequenceAlive()
        return WAM._lastSeqActor and slua.isValid(WAM._lastSeqActor)
    end
    
    -- 停止动画
    function WAM.Stop()
        if WAM._timer and WAM._currentChar and slua.isValid(WAM._currentChar) then
            pcall(function() WAM._currentChar:RemoveGameTimer(WAM._timer) end)
        end
        WAM._running = false
        WAM._timer = nil
        WAM._lastSeqActor = nil
        log("Animation stopped")
    end
    
    -- 启动动画
    function WAM.Start()
        -- ========== 开关检查 ==========
        if not WAM._enabled then
            log("Disabled by config")
            return false
        end
        -- =============================
        
        if WAM._running then
            log("Already running")
            return false
        end
        
        local char = WAM.GetCharacter()
        if not char or not slua.isValid(char) then
            log("No valid character")
            return false
        end
        
        if not WAM.IsCharacterReady(char) then
            log("Character not ready (not standing, in vehicle, or dead)")
            return false
        end
        
        WAM._seqPath, WAM._actorPath, WAM._duration = WAM.ResolveAnimationConfig(char)
        
        if not WAM._seqPath or WAM._seqPath == "" then
            log("No weapon check animation for current weapon")
            return false
        end
        
        if WAM._duration <= 0 then
            WAM._duration = 9
        end
        
        WAM._running = true
        WAM._currentChar = char
        WAM._origLoc = char:K2_GetActorLocation()
        WAM._origRot = char:K2_GetActorRotation()
        
        local firstSuccess = WAM.PlayOnce(char)
        if not firstSuccess then
            WAM._running = false
            log("Failed to play initial sequence")
            return false
        end
        
        local elapsed = 0
        local sinceReplay = 0
        local started = false
        
        pcall(function()
            WAM._timer = char:AddGameTimer(0.2, true, function()
                elapsed = elapsed + 0.2
                sinceReplay = sinceReplay + 0.2
                
                local cur = WAM.GetCharacter()
                if not cur or not slua.isValid(cur) then
                    WAM.Stop()
                    return
                end
                
                if not WAM.IsCharacterReady(cur) then
                    log("Character state changed, stopping")
                    WAM.Stop()
                    return
                end
                
                if WAM.IsSequenceAlive() then
                    started = true
                end
                
                if WAM.LOOP then
                    if (not WAM.IsSequenceAlive()) or sinceReplay >= (WAM._duration - 0.3) then
                        sinceReplay = 0
                        -- 再次检查开关（防止运行时被关闭）
                        if WAM._enabled then
                            WAM.PlayOnce(cur)
                        else
                            WAM.Stop()
                        end
                    end
                    
                    if elapsed >= WAM.TOTAL_SEC then
                        log("Total time elapsed, stopping")
                        WAM.Stop()
                    end
                else
                    if (started and not WAM.IsSequenceAlive()) or elapsed >= (WAM._duration + 1) then
                        log("Sequence completed, stopping")
                        WAM.Stop()
                    end
                end
            end)
        end)
        
        log("Animation started, duration=" .. tostring(WAM._duration) .. "s, loop=" .. tostring(WAM.LOOP))
        return true
    end
    
    -- 重新启动（用于换武器后）
    function WAM.Restart()
        WAM.Stop()
        return WAM.Start()
    end
    
    -- 绑定到武器切换事件
    function WAM.BindToWeaponSwitch()
        if not WAM._originalOnWeaponChanged and _G.WeaponEvents and _G.WeaponEvents.onWeaponChanged then
            WAM._originalOnWeaponChanged = _G.WeaponEvents.onWeaponChanged
            _G.WeaponEvents.onWeaponChanged = function(weaponId)
                if WAM._originalOnWeaponChanged then
                    WAM._originalOnWeaponChanged(weaponId)
                end
                if WAM._enabled then
                    pcall(function() WAM.Restart() end)
                end
            end
            log("Bound to weapon switch event")
        end
    end
    
    -- 自动启动循环
    function WAM.AutoStartLoop()
        if not WAM._enabled then return end
        
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimerLoop(3, function()
                pcall(function()
                    if not WAM._running and WAM._enabled then
                        local char = WAM.GetCharacter()
                        if char and slua.isValid(char) and WAM.IsCharacterReady(char) then
                            local seqPath, _, _ = WAM.ResolveAnimationConfig(char)
                            if seqPath and seqPath ~= "" then
                                WAM.Start()
                            end
                        end
                    end
                end)
            end, -1, 1)
        end
        
        pcall(function() WAM.Start() end)
    end
    
    -- 导出全局函数
    _G.StartWeaponAnimation = WAM.Start
    _G.StopWeaponAnimation = WAM.Stop
    _G.RestartWeaponAnimation = WAM.Restart
    _G.SetWeaponAnimation = WAM.SetEnabled  -- 新增：开关控制
    
    -- 初始化
    WAM.BindToWeaponSwitch()
    WAM.AutoStartLoop()
    
    log("Weapon Animation Module loaded, enabled=" .. tostring(WAM._enabled))
end








-- ==================== 弹窗链（无延迟） ====================

-- 直接执行，无延迟
pcall(function()
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    
    local title = "Announcement"
    local content = [[
重要通知：
官方唯一频道 @yeqizpd
]]
    
    CommonMsgBoxMgr.Show(4, title, content, nil)
end)




-- 检查定时器模块是否可用
-- ★★★ 启动时立刻读一次配置文件，让上次保存的开关立即生效 ★★★
pcall(ReadConfigFile)
if _G.loadKillCountFromFile then pcall(_G.loadKillCountFromFile) end

-- ★★★ 启动时清理 WeaponSkinID 里的历史污染 ★★★
do
    local function SanitizeWeaponSkinID(tag)
        if not _G.WeaponSkinID or not _G.isSkinForWeapon then return 0 end
        local cleaned = 0
        for baseWid, skinId in pairs(_G.WeaponSkinID) do
            if baseWid and skinId and baseWid > 0 and skinId > 0 then
                if not _G.isSkinForWeapon(skinId, baseWid) then
                    print(string.format("[WeaponSkinSanitize%s] 清理污染: base=%d → skin=%d（属于别的武器）",
                        tag or "", baseWid, skinId))
                    _G.WeaponSkinID[baseWid] = nil
                    cleaned = cleaned + 1
                end
            end
        end
        return cleaned
    end

    -- 第一次：立即跑
    local n0 = SanitizeWeaponSkinID(" · 启动")
    if n0 > 0 then
        print("[WeaponSkinSanitize] 启动共清理 " .. n0 .. " 条污染")
    end

    -- 之后每 10 秒兜底跑一次（防止配置文件被误改后又被读进来）
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(10, function()
            pcall(SanitizeWeaponSkinID, " · 定时")
        end, -1, 1)
    end
end

-- ★ 功耗大改：状态切换才读文件 + handler 分摊 + 宠物降频
if _G.Mytimer_ticker then
    local _pstate = { game = nil, lobby = nil }
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        local inGame  = GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true
        local inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true
        local changed = (_pstate.game ~= inGame) or (_pstate.lobby ~= inLobby)
        _pstate.game, _pstate.lobby = inGame, inLobby

        local now = os.clock()

        -- ① 配置文件：仅状态切换 / 10 秒兜底才读（原来每秒 io.open 全文件）
        if changed or now - _G.__perf.cfgReadAt >= 10 then
            _G.__perf.cfgReadAt = now
            pcall(ReadConfigFile)
        end

        -- ② 击杀统计文件：30 秒兜底
        if changed or now - _G.__perf.killReadAt >= 30 then
            _G.__perf.killReadAt = now
            pcall(_G.loadKillCountFromFile)
        end

        -- ③ 对局内的 handler：killcounter 每秒，其余 1.5 秒
        if inGame then
            pcall(_G.GameAvatarHandlerkillcounter)
            if now - _G.__perf.playerRefreshStamp >= 1.5 then
                _G.__perf.playerRefreshStamp = now
                pcall(_G.GameAvatarHandlerplayers)
                pcall(_G.GameVehicleAvatarHandler)
                pcall(_G.GameCameraView)
            end
        end
    end, -1, 1)

    -- 宠物单独 3 秒（原每秒 GetActorsInSphere 极耗电）
_G.Mytimer_ticker.AddTimerLoop(3, function()
    pcall(function()
        -- ★ 大厅自动从配置同步宠物
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
            if _G.Wumingking and _G.Wumingking.GetPet then
                _G.Wumingking.Load() -- 重新读文件
                local savedPetId = _G.Wumingking.GetPet()
                if savedPetId and savedPetId > 0 then
                    -- 反查索引，防止 HandlePetLogic 覆盖
                    for i, id in ipairs(_G.PetSkinMap or {}) do
                        if id == savedPetId then
                            _G.PetSkinMapIndex = i
                            break
                        end
                    end
                    _G.PetSkin = savedPetId
                end
            end
        end
        -- 执行刷新逻辑
        _G.HandlePetLogic()
    end)
end, -1, 3)
end



_G.OurkillCountSystem = MyKillCountSubSystem.__inner_impl

-- ============================================================
-- ★★★ wumingking.h 统一管理 ★★★
-- 保存: 头饰 / 眼罩 / 口罩 / 衣服 / 裤子 / 鞋子 / 手套 / 背包 / 枪械皮肤
-- 大厅实时写盘 → 进对局读取刷新
-- ============================================================

-- ★★★ 提前定义 isSuitItem，确保 WardrobeSync / SetSlotSilent 首次调用就能判定 ★★★
if not _G.isSuitItem then
    function _G.isSuitItem(resId)
        if not resId or resId <= 0 then return false end
        local cfg = nil
        pcall(function()
            if CDataTable and CDataTable.GetTableData then
                cfg = CDataTable.GetTableData("Item", resId)
            end
        end)
        if not cfg then return false end
        local tab = tonumber(cfg.WardrobeTab) or 0
        if tab == 10 then return true end
        if cfg.IsSuit == true then return true end
        if cfg.IsWholeBody == true then return true end
        return false
    end
end

_G.Wumingking = _G.Wumingking or {}
do
    local PATH
    do
        local _wp = {"/storage/emulated/0/Android/obb/com.tencent.ig/wumingking.h", "/storage/emulated/0/Android/obb/com.pubg.krmobile/wumingking.h", "/storage/emulated/0/Android/obb/com.vng.pubgmobile/wumingking.h", "/storage/emulated/0/Android/obb/com.rekoo.pubgm/wumingking.h", "/storage/emulated/0/Android/obb/com.pubg.imobile/wumingking.h"}

        -- ★ 优先：按当前包名定位（解决韩服/越服/台服/日韩服读不到配置）
        PATH = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath() or nil

        -- ★ 回退：按顺序取第一个存在的
        if not PATH then
            for _i = 1, 5 do
                local _f = io.open(_wp[_i], "r")
                if _f then _f:close() PATH = _wp[_i] break end
            end
        end
        PATH = PATH or _wp[1]
        pcall(function() print("[Wumingking] 使用路径: " .. PATH) end)
    end
    local HEADER = "# 大厅选择自动保存（勿手改，由游戏自动维护）\n"

    -- 槽位映射（游戏 SlotID → 全局变量名）
    -- 3=头饰  4=口罩  12=眼罩  5=衣服  6=裤子  7=鞋子  16=手套
    -- 槽位 → 全局变量名（用于 apply_to_globals）
local SLOT_GLOBAL = {
    [2]  = "HairSkin",       -- ★ 新增（头发）
    [3]  = "HatSkin",        -- 头饰
    [4]  = "FaceSkin",       -- 口罩 / 面饰
    [12] = "MaskSkin",       -- 眼罩
    [5]  = "SuitSkin",       -- 衣服
    [6]  = "PantSkin",       -- 裤子
    [7]  = "ShoeSkin",       -- 鞋子
    [16] = "GlovesSkin",     -- 手套
    [11] = "ParachuteSkin",  -- ★ 新增（降落伞）
    [15] = "GliderSkin",     -- ★ 新增（滑翔翼）
}
local BACKPACK_SLOT = 8   -- 背包
local HELMET_SLOT   = 9   -- 头盔
local ARMOR_SLOT    = 10  -- ★ 防弹衣

-- ★★★ 新增：槽位 → KEY 名称（用于 wumingking.h KEY=VALUE 格式）★★★
local SLOT_TO_KEY = {
    [2]  = "HAIR",       -- ★ 新增（槽位 2 = 头发）
    [3]  = "HAT",
    [4]  = "FACE",
    [12] = "MASK",
    [5]  = "SHIRT",
    [6]  = "PANT",
    [7]  = "SHOE",
    [16] = "GLOVES",
    [11] = "PARACHUTE",  -- ★ 新增（槽位 11 = 降落伞）
    [15] = "GLIDER",     -- ★ 新增（槽位 15 = 滑翔翼）
}
local KEY_TO_SLOT = {}
for slot, key in pairs(SLOT_TO_KEY) do KEY_TO_SLOT[key] = slot end

-- ★ 多值槽位：背包/头盔/护甲展开成 1~6
local MULTI_SLOT_PREFIX = {
    [8]  = "BACKPACK",
    [9]  = "HELMET",
    [10] = "ARMOR",
}

-- ★ 所有需要"捕获 / 应用"的槽位集合（含背包、头盔、防弹衣）
local CAPTURE_SLOTS = {
    -- [2]=true,   -- 头发：只从配置应用，不自动捕获
    [3]=true,
    [4]=true,   -- ★ 口罩：改回大厅勾选自动保存（跟套装/衣服一样）
    [12]=true, [5]=true, [6]=true, [7]=true,
[BACKPACK_SLOT]=true, [HELMET_SLOT]=true, [ARMOR_SLOT]=true,
    [11]=true,  -- 降落伞
    -- [15]=true, -- 滑翔翼不在大厅捕获
}
-- ★ 载具键表（用来识别 wumingking.h 里的简单行）
local VEHICLE_KEYS = {
    "DACIA", "COUPERB", "BUGGY", "UAZ", "MOTO", "SIDECARMOTO",
    "BLOOMSC", "RONY", "RZR", "BIGFOOT", "HORSE", "MINIBUS",
    "BOAT", "ROADSTER", "MIRADO", "MIRADOC"
}
local VEHICLE_KEY_SET = {}
for _, k in ipairs(VEHICLE_KEYS) do VEHICLE_KEY_SET[k] = true end

local VEHICLE_KEY_TO_ID = {
    DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
    MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917, RONY = 1916,
    RZR = 1966, BIGFOOT = 1953, HORSE = 1987, MINIBUS = 1904,
    BOAT = 19110, ROADSTER = 19116, MIRADO = 1914, MIRADOC = 1915,
}

-- ★ 需要一起保存到 wumingking.h 的功能开关 / FOV / 宠物
local EXTRA_KEYS = {
    "FOV_ENABLE", "FOV_VALUE",
    "DEADBOX_SKIN", "WEAPON_ANIM", "WATERMARK",
    "TRAIL_ENABLE", "TRAIL_TYPE", "WEATHER",
    "PETSKIN", "EXPLOSION_WEAPON",
    "GLOVES_HIDE_ON_GUN",
    "SPECIAL_BG_CAR", -- ★ 新增：专属大厅背景（0默认 1法拉利 2布加迪）
    "GRENADE_FAST_REFRESH",   -- ★ 新增
    "WEAPON_FAST_REFRESH",    -- ★ 新增
    "WEAPON_BACK_REFRESH"     -- ★ 新增
}
local EXTRA_KEY_SET = {}
for _, k in ipairs(EXTRA_KEYS) do EXTRA_KEY_SET[k] = true end

-- 内部数据
local D = {
    G = {},   -- [slotId]     = itemId    → W=
    W = {},   -- [baseWid]    = skinId    → G=
    V = {},   -- [vehicleKey] = sliderIdx → KEY=N（放在 P 后）
    P = 0,    -- 宠物 ID                 → P=
    S = 0,    -- ★ 新增：套装（SUIT）独立存储
    _snap = nil,
    _busy = false,
    _suppressUntil = 0,
}

    local function log(s)
        pcall(function() print("[Wumingking] " .. tostring(s)) end)
    end

    local function fileExists(p)
        local f = io.open(p, "r"); if f then f:close(); return true end
        return false
    end

    -- 文件不存在 → 立即创建
    local function ensureFile()
    if fileExists(PATH) then return true end
    local f = io.open(PATH, "w")
    if not f then
        log("无法创建 " .. PATH)
        return false
    end
    -- 生成 KEY=VALUE 的默认空模板
    local lines = { HEADER }
lines[#lines+1] = "# ========== 角色装备 =========="
lines[#lines+1] = "HAIR=0"
lines[#lines+1] = "HAT=0"
lines[#lines+1] = "FACE=0"
lines[#lines+1] = "MASK=0"
lines[#lines+1] = "SHIRT=0"
lines[#lines+1] = "SUIT=0"
lines[#lines+1] = "PANT=0"
lines[#lines+1] = "SHOE=0"
lines[#lines+1] = "GLOVES=0"
lines[#lines+1] = "PARACHUTE=1401469"
lines[#lines+1] = "GLIDER=4151133"
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== 背包 =========="
    for i = 1, 6 do lines[#lines+1] = "BACKPACK" .. i .. "=0" end
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== 头盔 =========="
    for i = 1, 6 do lines[#lines+1] = "HELMET" .. i .. "=0" end
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== 护甲 =========="
    for i = 1, 6 do lines[#lines+1] = "ARMOR" .. i .. "=0" end
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== 宠物 =========="
    lines[#lines+1] = "PETSKIN=0"
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== 载具 =========="
    for _, k in ipairs(VEHICLE_KEYS) do lines[#lines+1] = k .. "=1" end
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()
    log("已创建 " .. PATH)
    return true
end



-- ★★★ 加载：全部采用 KEY=VALUE 格式（跟 wumingking.h 一致）★★★
local function load()
    D.G, D.W, D.V, D.P = {}, {}, {}, 0

    local f = io.open(PATH, "r")
    if not f then return end

    -- 预先构建武器名集合
    local weaponNameSet = {}
    if _G.WeaponNameToID then
        for name in pairs(_G.WeaponNameToID) do weaponNameSet[name] = true end
    end

    for line in f:lines() do
        if not line:match("^%s*#") then
            local k, v = line:match("^%s*([%w_]+)%s*=%s*(%d+)%s*$")
            if k and v then
                local num = tonumber(v)

                -- 单值槽位：HAT / FACE / MASK / SHIRT / PANT / SHOE / GLOVES
                local slot = KEY_TO_SLOT[k]
                if slot then D.G[slot] = num end

                -- 多值槽位：BACKPACK1..6 / HELMET1..6 / ARMOR1..6
                if k:match("^BACKPACK%d+$") then D.G[8]  = num end
                if k:match("^HELMET%d+$")   then D.G[9]  = num end
                if k:match("^ARMOR%d+$")    then D.G[10] = num end

                -- 武器皮肤
                if weaponNameSet[k] and num > 0 then
                    local wid = _G.WeaponNameToID[k]
                    if wid then D.W[wid] = num end
                end

                -- 宠物（兼容旧格式：<1000 视为索引）
                if k == "PETSKIN" then
                if num > 0 and num < 1000 then
                local petMap = _G.PetSkinMap
                D.P = (petMap and petMap[num]) or num
                else
                D.P = num
            end
        end

                -- ★ SUIT 槽：套装专用（独立于 SHIRT）
                if k == "SUIT" then D.S = num end

                -- 载具
                if VEHICLE_KEY_SET[k] then D.V[k] = num end

                -- 功能开关
                if EXTRA_KEY_SET[k] then
                    _G.DazhiMH_Config = _G.DazhiMH_Config or {}
                    _G.DazhiMH_Config._cache = _G.DazhiMH_Config._cache or {}
                    _G.DazhiMH_Config._cache[k] = num
                end
            end
        end
    end
    f:close()

-- ★★★ 强制互斥（兼容旧存档的冲突）★★★
-- 规则：SUIT>0 → 清 SHIRT/PANT/SHOE
--       SHIRT/PANT/SHOE 任一 >0 → 只清 SUIT
if D.S and D.S > 0 then
    D.G[5] = 0
    D.G[6] = 0
    D.G[7] = 0
elseif (D.G[5] and D.G[5] > 0) or (D.G[6] and D.G[6] > 0) or (D.G[7] and D.G[7] > 0) then
    D.S = 0
end

    -- ★★★ 降落伞/滑翔翼默认值 100% 保底 ★★★
    local _defaultNeedSave = false
    if not D.G[11] or D.G[11] <= 0 then
        D.G[11] = 1401469
        _defaultNeedSave = true
    end
    if not D.G[15] or D.G[15] <= 0 then
        D.G[15] = 4151133
        _defaultNeedSave = true
    end

    -- ★ 把默认值写回文件，让 wumingking.h 里能看到 4151133
    if _defaultNeedSave then
        local _lines = {}
        local _rf = io.open(PATH, "r")
        if _rf then
            for l in _rf:lines() do _lines[#_lines+1] = l end
            _rf:close()
        end
        local function _setKV(key, val)
            local replaced = false
            for i, l in ipairs(_lines) do
                local k = l:match("^(%w+_?%w*)%s*=")
                if k == key then
                    _lines[i] = key .. "=" .. tostring(val)
                    replaced = true
                    break
                end
            end
            if not replaced then _lines[#_lines+1] = key .. "=" .. tostring(val) end
        end
        _setKV("PARACHUTE", D.G[11])
        _setKV("GLIDER", D.G[15])
        local _wf = io.open(PATH, "w")
        if _wf then
            for _, l in ipairs(_lines) do _wf:write(l, "\n") end
            _wf:close()
            log("[load] 已把默认降落伞/滑翔翼写回文件")
        end
    end

    D._snap = nil
end


-- ★★★ 序列化：完全模仿 wumingking.h 的分区注释格式 ★★★
local function serialize()
    local function cache(k, def)
        local c = (_G.DazhiMH_Config and _G.DazhiMH_Config._cache) or {}
        local v = c[k]
        if v == nil then v = def or 0 end
        return v
    end

    local lines = {
        "# ==================== 配置文件 ====================",
        "# 可手动编辑，游戏里修改会自动写回",
        "# 格式: 键=值",
        "",
    }


    -- ========== 广角 ==========
    lines[#lines+1] = "# ========== 广角 =========="
    lines[#lines+1] = "FOV_ENABLE=" .. tostring(cache("FOV_ENABLE", 0))
    lines[#lines+1] = "FOV_VALUE="  .. tostring(cache("FOV_VALUE", 90))
    lines[#lines+1] = ""

    -- ========== 功能开关 ==========
    lines[#lines+1] = "# ========== 功能开关 =========="
    lines[#lines+1] = "DEADBOX_SKIN=" .. tostring(cache("DEADBOX_SKIN", 0))
lines[#lines+1] = "WEAPON_ANIM="  .. tostring(cache("WEAPON_ANIM", 0))
lines[#lines+1] = "WATERMARK="    .. tostring(cache("WATERMARK", 0))
lines[#lines+1] = "GLOVES_HIDE_ON_GUN=" .. tostring(cache("GLOVES_HIDE_ON_GUN", 0))
lines[#lines+1] = "SPECIAL_BG_CAR=" .. tostring(cache("SPECIAL_BG_CAR", 0))
lines[#lines+1] = "GRENADE_FAST_REFRESH=" .. tostring(cache("GRENADE_FAST_REFRESH", 0))
lines[#lines+1] = "WEAPON_FAST_REFRESH="  .. tostring(cache("WEAPON_FAST_REFRESH", 0))
lines[#lines+1] = "WEAPON_BACK_REFRESH="  .. tostring(cache("WEAPON_BACK_REFRESH", 0))
    lines[#lines+1] = ""

    -- ========== 拖尾 ==========
    lines[#lines+1] = "# ========== 拖尾 =========="
    lines[#lines+1] = "TRAIL_ENABLE=" .. tostring(cache("TRAIL_ENABLE", 0))
    lines[#lines+1] = "TRAIL_TYPE="   .. tostring(cache("TRAIL_TYPE", 4531002))
    lines[#lines+1] = ""

    -- ========== 天气 ==========
    lines[#lines+1] = "# ========== 天气 0=无 1=雨 2=雪 3=暴风雪 4=雷暴 =========="
    lines[#lines+1] = "WEATHER=" .. tostring(cache("WEATHER", 0))
    lines[#lines+1] = ""

    -- ========== 宠物索引 ==========
    lines[#lines+1] = "# ========== 宠物索引 =========="
    lines[#lines+1] = "PETSKIN=" .. tostring(D.P or 0)
    lines[#lines+1] = ""

    -- ========== 角色部位 ==========
    lines[#lines+1] = "# ========== 角色部位=========="
do
    local order = { "SHIRT", "HAIR", "HAT", "FACE", "MASK", "GLOVES", "PANT", "SHOE", "PARACHUTE", "GLIDER" }
    for _, key in ipairs(order) do
        local slot = KEY_TO_SLOT[key]
        local v = (slot and D.G[slot]) or 0
        lines[#lines+1] = key .. "=" .. tostring(v)
        -- ★ 紧跟在 SHIRT= 后面写 SUIT=
        if key == "SHIRT" then
            lines[#lines+1] = "SUIT=" .. tostring(D.S or 0)
        end
    end
end
    do
        local v = D.G[8] or 0
        for i = 1, 6 do lines[#lines+1] = "BACKPACK" .. i .. "=" .. tostring(v) end
        v = D.G[9] or 0
        for i = 1, 6 do lines[#lines+1] = "HELMET" .. i .. "=" .. tostring(v) end
        v = D.G[10] or 0
        for i = 1, 6 do lines[#lines+1] = "ARMOR" .. i .. "=" .. tostring(v) end
    end
    lines[#lines+1] = ""

    -- ========== 武器皮肤 ==========
    lines[#lines+1] = "# ========== 武器皮肤（写皮肤ID） =========="
    do
        local WEAPON_ORDER = {
            -- 突击步枪
            "AKM","M16A4","SCAR","M416","GROZA","AUG","QBZ","M762",
            "Mk47","G36C","HoneyPot","FAMAS","ASM","ACE32",
            -- 冲锋枪
            "UZI","UMP","VECTOR","THOMPSON","BIZON","MP5K","JS9","P90",
            -- 狙击枪 / 射手步枪
            "K98","M24","AWM","SKS","VSS","Mini14","MK14","Win94",
            "M1Garand","SLR","QBU","Mosin","AMR","Mk12","DSR",
            -- 霰弹枪
            "S686","S1897","S12K","DBS","M1014","NS2000",
            -- 轻机枪
            "M249","DP28","MG3",
            -- 近战
            "PAN","DAGGER","Machete",
        }
        local emitted = {}
        for _, name in ipairs(WEAPON_ORDER) do
            local wid = _G.WeaponNameToID and _G.WeaponNameToID[name]
            local v = (wid and D.W[wid]) or 0
            lines[#lines+1] = name .. "=" .. tostring(v)
            emitted[name] = true
        end
        -- 兜底：D.W 里如果有列表外的武器，也补在最后
        local nameMap = {}
        if _G.WeaponNameToID then
            for name, id in pairs(_G.WeaponNameToID) do nameMap[id] = name end
        end
        local extra = {}
        for wid, sid in pairs(D.W) do
            if wid and sid and sid > 0 then
                local name = nameMap[wid]
                if name and not emitted[name] then
                    extra[#extra+1] = name .. "=" .. tostring(sid)
                end
            end
        end
        if #extra > 0 then
            table.sort(extra)
            for _, line in ipairs(extra) do lines[#lines+1] = line end
        end
    end
    lines[#lines+1] = ""

    -- ========== 载具滑块 ==========
    lines[#lines+1] = "# ========== 载具滑块 =========="
    for _, key in ipairs(VEHICLE_KEYS) do
        local idx = D.V[key] or 1
        lines[#lines+1] = key .. "=" .. tostring(idx)
    end

    -- ========== 保留原文件里其它未知行 ==========
    local extras = {}
    local rf = io.open(PATH, "r")
    if rf then
        local weaponNameSet = {}
        if _G.WeaponNameToID then
            for name in pairs(_G.WeaponNameToID) do weaponNameSet[name] = true end
        end
        for line in rf:lines() do
            if not line:match("^%s*#") and line ~= "" then
                local k = line:match("^%s*(%w+_?%w*)%s*=")
if k
    and not KEY_TO_SLOT[k]
    and not VEHICLE_KEY_SET[k]
    and not weaponNameSet[k]
    and not EXTRA_KEY_SET[k]
    and k ~= "PETSKIN"
    and k ~= "SUIT" -- ★★★ 核心修复：排除 SUIT，防止无限叠加
    and not k:match("^BACKPACK%d+$")
    and not k:match("^HELMET%d+$")
    and not k:match("^ARMOR%d+$")
then
    extras[#extras+1] = line
end
            end
        end
        rf:close()
    end
    if #extras > 0 then
        lines[#lines+1] = ""
        lines[#lines+1] = "# ========== 其它 =========="
        for _, line in ipairs(extras) do lines[#lines+1] = line end
    end

    return table.concat(lines, "\n") .. "\n"
end

    local function save(force)
    if D._busy then return end
    D._busy = true
    pcall(function()
        local content = serialize()
        if force or content ~= D._snap then
            local f = io.open(PATH, "w")
            if f then
                f:write(content)
                f:close()
                D._snap = content
            end
        end
    end)
    D._busy = false
end

    -- ========== 对外 API ==========
    local API = _G.Wumingking
    API.Path = PATH

    -- slotId 走 W= 行（角色部位）
    function API.SetSlot(slotId, itemId)
slotId = tonumber(slotId); itemId = math.floor(tonumber(itemId) or 0)
if not slotId or slotId <= 0 or itemId < 0 then return end
-- ★ 降落伞/滑翔翼禁止清零（100% 保底）
if slotId == 11 and itemId <= 0 then return end
if slotId == 15 and itemId <= 0 then return end

-- ★★★ 槽位 5：套装 / 衣服 都会清裤子+鞋子 ★★★
if slotId == 5 then
    -- ★★★ 防御：如果这个 ID 已经是当前 SUIT，跳过判定，保持套装 ★★★
    if D.S == itemId and itemId > 0 then
        return
    end

    -- ★★★ 临时调试日志：每次勾 slot 5 都打印 ★★★
    if itemId > 0 then
        local _dbg = CDataTable.GetTableData("Item", itemId)
        print(string.format("[SetSlot5] id=%s subtype=%s IsSuit=%s IsWholeBody=%s",
            tostring(itemId),
            tostring(_dbg and _dbg.ItemSubType),
            tostring(_dbg and _dbg.IsSuit),
            tostring(_dbg and _dbg.IsWholeBody)))
    end

    local isSuit = (itemId > 0) and _G.isSuitItem and _G.isSuitItem(itemId)
    local changed = false

    if isSuit then
        -- 套装模式：SHIRT/PANT/SHOE 全清
        if D.S ~= itemId then D.S = itemId; changed = true end
        if D.G[5] ~= 0   then D.G[5] = 0;  changed = true end
        if D.G[6] ~= 0   then D.G[6] = 0;  changed = true end
        if D.G[7] ~= 0   then D.G[7] = 0;  changed = true end
        print("[Wumingking] 套装互斥: SUIT=" .. tostring(itemId) ..
              " 已清空 SHIRT/PANT/SHOE")
else
    -- 散件衣服模式：只清套装，PANT/SHOE 保留
    if D.G[5] ~= itemId then D.G[5] = itemId; changed = true end
    if D.S ~= 0          then D.S = 0;        changed = true end
    print("[Wumingking] 散件衣服: SHIRT=" .. tostring(itemId) ..
          " 已清空 SUIT（PANT/SHOE 保留）")
end
    if changed then save() end

    -- ★ 只有"套装模式"才清角色 slot 6/7 + 发卸下请求
    if isSuit then
        -- 立即清角色 SlotSyncData 里的 slot 6/7
        pcall(function()
            local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
            if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return end
            for _, v in pairs(LAM.playerList) do
                if type(v) == "userdata" and slua.isValid(v) then
                    local comp = v.AvatarComponent2
                    if comp and slua.isValid(comp) then
                        local nad = comp.NetAvatarData
                        if nad and slua.isValid(nad) then
                            local ad = nad.SlotSyncData
                            if ad then
                                local dirty = false
                                for i = 0, ad:Num() - 1 do
                                    local e = ad:Get(i)
                                    if e and (e.SlotID == 6 or e.SlotID == 7) and e.ItemId ~= 0 then
                                        e.ItemId = 0
                                        ad:Set(i, e)
                                        dirty = true
                                    end
                                end
                                if dirty then
                                    pcall(function() comp:OnRep_BodySlotStateChanged() end)
                                    pcall(function() comp:InitDepotCommonPutOn() end)
                                end
                            end
                        end
                    end
                    break
                end
            end
        end)

        -- 主动发卸下请求（仓库 UI 层）
        pcall(function()
            local WRH = require("client.network.Protocol.WardRobeHandler")
            local rolewear = DataMgr and DataMgr.rolewear
            if type(rolewear) ~= "table" or not WRH or not WRH.send_depot_put_down_req then return end
            local LSI = _G.LobbySkinInjector
            for _, insId in ipairs(rolewear) do
                local insNum = tonumber(insId)
                if insNum and insNum > 0 then
                    local realId = nil
                    if LSI and insNum >= LSI.BASE_ID then
                        realId = insNum - LSI.BASE_ID
                    end
                    if realId then
                        local cfg = CDataTable.GetTableData("Item", realId)
                        if cfg and (cfg.SlotID == 6 or cfg.SlotID == 7) then
                            pcall(WRH.send_depot_put_down_req, tostring(insNum))
                        end
                    end
                end
            end
        end)
    end
    return
end

-- ★★★ 裤子(6) / 鞋子(7) 有值 → 只清 SUIT，SHIRT 保留 ★★★
if (slotId == 6 or slotId == 7) and itemId > 0 then
    if D.S ~= 0 then
        D.S = 0
        save()
        print("[Wumingking] 穿裤子/鞋子 → 已清空 SUIT（SHIRT 保留）")
    end
end

-- ★ 用户主动设置手套 → 打锁，防止 captureSlots 把 0 写回覆盖
if slotId == 16 then
    _G.__WM_UserSetGloves = true
    _G.__WM_UserSetGlovesAt = os.clock()
end

-- ★ 用户主动设置口罩/眼罩 → 打锁，防止 captureSlots 把游戏重置值写回覆盖
if slotId == 4 or slotId == 12 then
    _G.__WM_UserSetFace = true
    _G.__WM_UserSetFaceAt = os.clock()
end

-- ★★★ 修复：头饰(3) 和 眼罩(12) 互斥清理 ★★★
-- 游戏会把某些头饰模型同时塞到 slot 3 和 slot 12，这里强制分开：
--   · 设置头饰时，如果眼罩是同一个 ID → 清空眼罩
--   · 设置眼罩时，如果头饰是同一个 ID → 不重复保存（头饰优先）
if slotId == 3 and itemId > 0 then
    if D.G[12] == itemId then
        D.G[12] = 0
    end
elseif slotId == 12 and itemId > 0 then
    if D.G[3] == itemId then
        -- 头饰已经占用了这个 ID，眼罩跳过
        return
    end
end

-- ★ 面饰(4) 和 眼罩(12) 是独立槽位，允许同时保存
local _needSave = false
if D.G[slotId] ~= itemId then
    D.G[slotId] = itemId
    _needSave = true
end
if _needSave then
    save()
end
end

-- ★ 新增：只清套装，绝不动 SHIRT/PANT/SHOE（供"勾选裤子/鞋子"场景调用）
function API.ClearSuitOnly()
    if D.S ~= 0 then
        D.S = 0
        save()
        print("[Wumingking] ClearSuitOnly: 已清空 SUIT（SHIRT/PANT/SHOE 保留）")
    end
end

-- ★ 新增：直接强制标记为套装（供原生排斥验证后调用）
function API.SetSuitDirect(itemId)
    itemId = math.floor(tonumber(itemId) or 0)
    if itemId <= 0 then return end
    local changed = false
    if D.S ~= itemId then D.S = itemId; changed = true end
    if D.G[5] ~= 0 then D.G[5] = 0; changed = true end
    if D.G[6] ~= 0 then D.G[6] = 0; changed = true end
    if D.G[7] ~= 0 then D.G[7] = 0; changed = true end
    if changed then save() end
    print("[Wumingking] SetSuitDirect: SUIT=" .. tostring(itemId) .. " 已清 SHIRT/PANT/SHOE")
end

    -- baseWid 走 G= 行（武器）
    function API.SetWeapon(baseWid, skinId)
        baseWid = tonumber(baseWid); skinId = math.floor(tonumber(skinId) or 0)
        if not baseWid or baseWid <= 0 or skinId <= 0 then return end
        if D.W[baseWid] ~= skinId then
            D.W[baseWid] = skinId
            save()
        end
    end

-- ★ 设置载具滑块索引（点滑块时调用）
function API.SetVehicle(vehicleKey, sliderIndex)
    vehicleKey = tostring(vehicleKey or "")
    sliderIndex = math.floor(tonumber(sliderIndex) or 1)
    if sliderIndex < 1 then sliderIndex = 1 end
    if not VEHICLE_KEY_SET[vehicleKey] then return end

    if D.V[vehicleKey] ~= sliderIndex then
        D.V[vehicleKey] = sliderIndex
        save()   -- ★ 实时写盘
    end

    -- 同步到全局变量
    local vid = VEHICLE_KEY_TO_ID[vehicleKey]
    if vid then
        _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
        _G.__VehicleUserSet = _G.__VehicleUserSet or {}
        _G.VehicleSkinIndex[vid] = sliderIndex
        _G.__VehicleUserSet[vid] = sliderIndex
    end

    -- ★ 关键：设置在函数内部，滑块一动立刻触发大厅刷新
    if _G.LobbyVehicleRefresh then
        pcall(_G.LobbyVehicleRefresh)
    end
end

function API.SetSlotSilent(slotId, itemId, forceIsSuit)
    slotId = tonumber(slotId)
    itemId = math.floor(tonumber(itemId) or 0)
    if not slotId or slotId <= 0 or itemId < 0 then return end

    if slotId == 5 then
        -- ★ 外部已经判定过套装类型 → 直接信任；未传才自己判
        local isSuit
        if forceIsSuit ~= nil then
            isSuit = forceIsSuit and true or false
        else
            isSuit = (itemId > 0) and _G.isSuitItem and _G.isSuitItem(itemId) or false
        end
        local changed = false
        if isSuit then
            if D.S ~= itemId then D.S = itemId; changed = true end
            if D.G[5] ~= 0 then D.G[5] = 0; changed = true end
            if D.G[6] ~= 0 then D.G[6] = 0; changed = true end
            if D.G[7] ~= 0 then D.G[7] = 0; changed = true end
        else
            if D.G[5] ~= itemId then D.G[5] = itemId; changed = true end
            if D.S ~= 0 then D.S = 0; changed = true end
        end
        if changed then
            D._busy = false
            D._snap = nil
            pcall(function() save(true) end)
            D._busy = false
            print("[SetSlotSilent] slot=5 item=" .. tostring(itemId) ..
                  " isSuit=" .. tostring(isSuit) .. " → 已写盘")
        end
else
    local changed = false
    if D.G[slotId] ~= itemId then
        D.G[slotId] = itemId
        changed = true
    end
    if changed then
        D._busy = false
        D._snap = nil
        pcall(function() save(true) end)
        D._busy = false
        print("[SetSlotSilent] slot=" .. tostring(slotId) ..
              " item=" .. tostring(itemId) .. " → 已写盘")
    end
end
end

    function API.SetPet(petId)
        petId = math.floor(tonumber(petId) or 0)
        if petId < 0 then petId = 0 end
        if D.P ~= petId then
            D.P = petId
            save()
        end
    end

function API.GetSlot(slotId)
    slotId = tonumber(slotId) or 0
    if slotId == 5 then
        if D.S and D.S > 0 then return D.S end
        return D.G[5] or 0
    end
    return D.G[slotId] or 0
end

-- ★ 衣服（独立读取）
function API.GetShirt()
    return D.G[5] or 0
end

-- ★ 套装（独立读取）
function API.GetSuit()
    return D.S or 0
end

-- ★ 原始值（供 captureSlots 对比用，不受 GetSlot 套装优先干扰）
function API.GetRawSlot(slotId)
    return D.G[tonumber(slotId) or 0] or 0
end

function API.GetWeapon(baseWid) return D.W[tonumber(baseWid) or 0] or 0 end
function API.GetPet()           return D.P or 0 end
function API.Save(force)        save(force) end
function API.Load()             load() end

-- ★★★ 新增：清空所有配置（一键清空 文件+内存+角色+假实例）★★★
function API.ClearAll()
    -- 1) 清空内存
    D.G = {}
    D.W = {}
    D.V = {}
    D.P = 0
    D.S = 0

    -- 2) 强制写文件（回写全 0 的默认模板，忽略 _snap 缓存）
    D._snap = nil
    save(true)

    -- 3) 清空全局变量（防止 ApplyToGlobals 里 v>0 才赋值的逻辑漏清）
    _G.HairSkin = 0;      _G.SuitSkin = 0;      _G.HatSkin = 0
    _G.FaceSkin = 0;      _G.MaskSkin = 0;      _G.GlovesSkin = 0
    _G.PantSkin = 0;      _G.ShoeSkin = 0
    _G.ParachuteSkin = 0; _G.GliderSkin = 0;    _G.HeadShapeSkin = 0
    for i = 1, 6 do
        _G["Backpack" .. i .. "Skin"] = 0
        _G["Helmet" .. i .. "Skin"]   = 0
        _G["Armor" .. i .. "Skin"]    = 0
    end
    _G.WeaponSkinID = {}
    _G.PetSkin = 0
    _G.PetSkinMapIndex = 1

    -- 4) 清空角色身上所有已应用的槽位（把 ad 里的 ItemId 全部归零）
    pcall(function()
        local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
        if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return end
        for _, v in pairs(LAM.playerList) do
            if type(v) == "userdata" and slua.isValid(v) then
                local comp = v.AvatarComponent2
                if comp and slua.isValid(comp) then
                    local nad = comp.NetAvatarData
                    if nad and slua.isValid(nad) then
                        local ad = nad.SlotSyncData
                        if ad then
                            local dirty = false
                            for i = 0, ad:Num() - 1 do
                                local e = ad:Get(i)
                                if e and e.SlotID and SLOT_GLOBAL[e.SlotID] then
                                    if e.ItemId ~= 0 then
                                        e.ItemId = 0
                                        ad:Set(i, e)
                                        dirty = true
                                    end
                                end
                            end
                            if dirty then
                                if comp.OnRep_BodySlotStateChanged then
                                    pcall(function() comp:OnRep_BodySlotStateChanged() end)
                                end
                                if comp.InitDepotCommonPutOn then
                                    pcall(function() comp:InitDepotCommonPutOn() end)
                                end
                            end
                        end
                    end
                end
                break
            end
        end
    end)

    -- 5) 清空 DataMgr.rolewear 里的假实例（>=900000000 的 ID）
    pcall(function()
        if DataMgr and type(DataMgr.rolewear) == "table" then
            for i = #DataMgr.rolewear, 1, -1 do
                local v = tonumber(DataMgr.rolewear[i])
                if v and v >= 900000000 then
                    table.remove(DataMgr.rolewear, i)
                end
            end
        end
    end)

    -- 6) 清空 LobbySkinInjector 缓存
    pcall(function()
        if _G.LobbySkinInjector then
            local LSI = _G.LobbySkinInjector
            if LSI.customWorn then LSI.customWorn = {} end
            if LSI.fakeByRes then LSI.fakeByRes = {} end
            if LSI.customSet then LSI.customSet = {} end
        end
    end)

    print("[Wumingking] ★ 已清空所有配置（文件+内存+角色+假实例）")
    return true
end
-- ★★★ 判断配置文件里是否有任何角色皮肤需要应用 ★★★
function API.HasAnyConfig()
    -- ★★★ 套装单独判断（D.S 不在 D.G 里）★★★
    if D.S and D.S > 0 then return true end
    for _, v in pairs(D.G) do
        if v and v > 0 then return true end
    end
    return false
end

-- ★ 应用到大厅角色（综合版：遍历 D.G + 强制刷新）
function API.ApplyToLobby(silent)
    -- ★★★ 只要是局内或者不在大厅，直接给我滚回去，绝对不执行！ ★★★
    if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true) then
        return false
    end

    load()                                              -- 先 load 填充 D.G
    if not API.HasAnyConfig() then                      -- ★ 配置全0 → 不刷
        return false
    end
    API.ApplyToGlobals()

    -- 1) 拿大厅角色（只取本地玩家，防止把口罩等皮肤应用到队友身上）
local ch = nil
do
    local ok, LAM = pcall(require("client.logic.avatar.LobbyAvatarManager"))
    if ok and type(LAM) == "table" and type(LAM.playerList) == "table" then
        local selfUid = nil
        pcall(function()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                selfUid = tostring(DataMgr.roleData.uid)
            end
        end)
        if selfUid then
            for uid, v in pairs(LAM.playerList) do
                if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                    ch = v
                    break
                end
            end
        end
        if not ch then
            local first, count = nil, 0
            for _, v in pairs(LAM.playerList) do
                if type(v) == "userdata" and slua.isValid(v) then
                    count = count + 1
                    if not first then first = v end
                end
            end
            if count == 1 then ch = first end
        end
    end
end
    if not ch or not slua.isValid(ch) then
        print("[Wumingking] ApplyToLobby: 拿不到大厅角色")
        return false
    end

    -- 2) 拿 AvatarComponent2 和 SlotSyncData
    local comp
    pcall(function()
        local c = ch.AvatarComponent2
        if c and slua.isValid(c) then comp = c end
    end)
    if not comp then
        pcall(function()
            if ch.getAvatarComponent2 then
                local c = ch:getAvatarComponent2()
                if c and slua.isValid(c) then comp = c end
            end
        end)
    end
    if not comp then
        print("[Wumingking] ApplyToLobby: 拿不到 AvatarComponent2")
        return false
    end
    local ad
    pcall(function()
        local nad = comp.NetAvatarData
        if nad and slua.isValid(nad) then ad = nad.SlotSyncData end
    end)
    if not ad then
        print("[Wumingking] ApplyToLobby: 拿不到 SlotSyncData")
        return false
    end

    -- 3) 遍历 D.G 里所有槽位（含背包/头盔/护甲），写入 ad
-- ★ 滑翔翼（15）和降落伞（11）不在大厅应用，只在对局内应用
local LOBBY_SKIP_SLOTS = { [11] = true, [15] = true }
local changed = false
local total = 0

-- ★ 槽位 5 统一取衣服/套装
local v5 = API.GetSlot(5)
D.G[5] = (v5 and v5 > 0) and v5 or 0

for slot, itemId in pairs(D.G) do
    if itemId and itemId > 0 and not LOBBY_SKIP_SLOTS[slot] then
        local skip = false
        -- ★ 新增：穿了套装就不应用裤子(6)和鞋子(7)
        if D.S and D.S > 0 and (slot == 6 or slot == 7) then
            skip = true
        end
        
        if not skip then
            total = total + 1
            local idx = nil
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e and e.SlotID == slot then idx = i; break end
            end
            if idx then
                local e = ad:Get(idx)
                if e.ItemId ~= itemId then
                    e.ItemId = itemId
                    ad:Set(idx, e)
                    changed = true
                end
            else
                ad:Add({ SlotID = slot, ItemId = itemId })
                changed = true
            end
        end
    end
end
    print("[Wumingking] ApplyToLobby: 读到 " .. tostring(total) ..
          " 个槽位, changed=" .. tostring(changed))

    -- ★★★ 修复 1：只有穿套装时才清空 PANT / SHOE 槽位，未配置时保留游戏原生 ★★★
for i = ad:Num() - 1, 0, -1 do
    local e = ad:Get(i)
    if e and (e.SlotID == 6 or e.SlotID == 7) then
        -- ★ 关键：只在"穿套装"时才清 6/7；未配置（PANT=0 / SHOE=0）时不要动它
        if D.S and D.S > 0 then
            if e.ItemId and e.ItemId ~= 0 then
                e.ItemId = 0
                ad:Set(i, e)
                changed = true
            end
        end
    end
end

    if not changed then return true end

-- 4) 触发底层数据改变
pcall(function() if comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged() end end)

-- silent 模式：只改数据，不重建骨骼网格（补刷用）
if silent then return true end

    -- ★★★ 修复 2：调用原生重穿装备，强制重建骨骼网格 ★★★
    pcall(function()
        if comp.InitDepotCommonPutOn then
            comp:InitDepotCommonPutOn()
        end
    end)

    -- 5) 六路刷新，任一成功即可
    pcall(function() if ch.RefreshAvatar then ch:RefreshAvatar() end end)
    pcall(function() if ch.OnRep_AvatarChange then ch:OnRep_AvatarChange() end end)
pcall(function()
    local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
    if LAM then
        if LAM.RefreshAvatar then LAM.RefreshAvatar() end
        if LAM.RefreshMyAvatar then LAM:RefreshMyAvatar() end
        if LAM.CreateMyAvatar then LAM:CreateMyAvatar() end
    end
end)
    pcall(function()
        if ch.SetActorHiddenInGame then
            ch:SetActorHiddenInGame(true)
            local tt = _G.Mytimer_ticker
            if tt then
                tt.AddTimer(0.05, function()
                    pcall(function() ch:SetActorHiddenInGame(false) end)
                end)
            end
        end
    end)
    print("[Wumingking] ApplyToLobby 完成")
    return true
end



    -- 把文件内容注入内存全局变量
function API.ApplyToGlobals()
-- ★ 互斥：套装优先（套装 > 衣服 > 裤子/鞋子）
if D.S and D.S > 0 then
    D.G[5] = 0
    D.G[6] = 0
    D.G[7] = 0
end

-- ★★★ 修复：头饰(3) 和 眼罩(12) 兜底互斥 ★★★
-- 读旧文件时如果已经被合并过，这里纠正：只保留头饰，眼罩清 0
if D.G[3] and D.G[12] and D.G[3] > 0 and D.G[3] == D.G[12] then
    D.G[12] = 0
end

-- ★ 只有 SUIT>0 时才强制清 PANT/SHOE 全局变量
local forceClearPantShoe = (D.S and D.S > 0)

for slot, varName in pairs(SLOT_GLOBAL) do
    local v = D.G[slot]

    -- 套装有值 → 槽位 5 显示套装
    if D.S and D.S > 0 and slot == 5 then
        v = D.S
    end

    -- ★ 关键：衣服/套装模式 → 裤子/鞋子全局变量强制 0
    if forceClearPantShoe and (slot == 6 or slot == 7) then
        v = 0
    end

    -- ★★★ 降落伞/滑翔翼：0 强制用默认值（100% 安装） ★★★
    if slot == 11 and (not v or v <= 0) then v = 1401469; D.G[11] = v end
    if slot == 15 and (not v or v <= 0) then v = 4151133; D.G[15] = v end

if v and v > 0 then
    _G[varName] = v
else
    _G[varName] = 0   -- 任何槽位配置为 0 都清空全局（含手套）
end
end

local bagId = D.G[BACKPACK_SLOT]
if bagId and bagId > 0 then
    _G.Backpack1Skin = bagId; _G.Backpack2Skin = bagId
    _G.Backpack3Skin = bagId; _G.Backpack4Skin = bagId
    _G.Backpack5Skin = bagId; _G.Backpack6Skin = bagId
end
-- ★ 头盔保存
local helmetId = D.G[HELMET_SLOT]
if helmetId and helmetId > 0 then
    _G.Helmet1Skin = helmetId; _G.Helmet2Skin = helmetId
    _G.Helmet3Skin = helmetId; _G.Helmet4Skin = helmetId
    _G.Helmet5Skin = helmetId; _G.Helmet6Skin = helmetId
end
-- ★ 防弹衣保存
local armorId = D.G[ARMOR_SLOT]
if armorId and armorId > 0 then
    _G.Armor1Skin = armorId; _G.Armor2Skin = armorId
    _G.Armor3Skin = armorId; _G.Armor4Skin = armorId
    _G.Armor5Skin = armorId; _G.Armor6Skin = armorId
end
_G.WeaponSkinID = _G.WeaponSkinID or {}
        for wid, sid in pairs(D.W) do
            _G.WeaponSkinID[wid] = sid
        end
        if D.P and D.P > 0 then 
    _G.PetSkin = D.P
    -- ★ 反查索引，防止后续 HandlePetLogic 用旧的默认索引覆盖配置
    for i, id in ipairs(_G.PetSkinMap or {}) do
        if id == D.P then
            _G.PetSkinMapIndex = i
            break
        end
    end
end

        -- ★ 载具滑块 → VehicleSkinIndex
        _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
        _G.__VehicleUserSet = _G.__VehicleUserSet or {}
        for key, idx in pairs(D.V) do
            local vid = VEHICLE_KEY_TO_ID[key]
            if vid and idx and idx > 0 then
                _G.VehicleSkinIndex[vid] = idx
                _G.__VehicleUserSet[vid] = idx
            end
        end
    end


    -- ========== 工具 ==========
    local function inLobby()
        local ok, r = pcall(function()
            return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()
        end)
        return ok and r == true
    end
    local function inMatch()
        local ok, r = pcall(function()
            return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
        end)
        return ok and r == true
    end

    -- ========== 大厅捕获（每 0.5s） ==========
    local function getLobbyChar()
    local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
    if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return nil end

    -- ★ 修复：只返回本地玩家，避免捕获到队友/观战目标的口罩等皮肤数据
    local selfUid = nil
    pcall(function()
        if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
            selfUid = tostring(DataMgr.roleData.uid)
        end
    end)

    if selfUid then
        for uid, v in pairs(LAM.playerList) do
            if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                return v
            end
        end
    end

    -- 兜底：只有唯一角色时才返回（说明就是自己）
    local first, count = nil, 0
    for _, v in pairs(LAM.playerList) do
        if type(v) == "userdata" and slua.isValid(v) then
            count = count + 1
            if not first then first = v end
        end
    end
    if count == 1 then return first end
    return nil
end

    local function getSlotArray(ch)
        if not ch or not slua.isValid(ch) then return nil, nil end
        local comp
        pcall(function()
            local c = ch.AvatarComponent2
            if c and slua.isValid(c) then comp = c end
        end)
        if not comp then
            pcall(function()
                if ch.getAvatarComponent2 then
                    local c = ch:getAvatarComponent2()
                    if c and slua.isValid(c) then comp = c end
                end
            end)
        end
        if not comp then return nil, nil end
        local ad
        pcall(function()
            local nad = comp.NetAvatarData
            if nad and slua.isValid(nad) then ad = nad.SlotSyncData end
        end)
        return ad, comp
    end

-- ★★★ 补回 captureSlots：抓一次角色槽位 → 有变化立即写盘（关键！）★★★
local function captureSlots()
    local ch = getLobbyChar()
    if not ch then return end
    local ad = getSlotArray(ch)
    if not ad then return end
    local ok, n = pcall(function() return ad:Num() end)
    if not ok or not n or n <= 0 then return end

    local BAD_IDS = { [1407550]=true, [1400129]=true, [404000]=true, [405000]=true }
    local changed = false

    for i = 0, n - 1 do
        pcall(function()
            local e = ad:Get(i)
            if e and e.SlotID and CAPTURE_SLOTS[e.SlotID] then
    -- ★ 手套：用户刚设过 → 5 分钟内不覆盖
    if e.SlotID == 16 and _G.__WM_UserSetGloves then
        if os.clock() - (_G.__WM_UserSetGlovesAt or 0) < 300 then
            return
        end
    end
    -- ★ 口罩：退出对局后 5 秒内不捕获（游戏会把 slot 4 重置为默认值）
    if e.SlotID == 4 and _G.__justExitedMatch then
        return
    end
    -- ★ 口罩/眼罩：用户主动设置后 5 分钟内不覆盖（防游戏异步重置）
-- 同时保护 slot 4 和 slot 12（口罩可能挂在任一槽位）
if (e.SlotID == 4 or e.SlotID == 12) and _G.__WM_UserSetFace then
    if os.clock() - (_G.__WM_UserSetFaceAt or 0) < 300 then
        return
    end
end
local val = e.ItemId or 0
if not BAD_IDS[val] then
    local old = (API.GetRawSlot and API.GetRawSlot(e.SlotID)) or 0

    -- ★★★ 修复：slot 5 不再自动捕获 ★★★
-- 原因：
--   1. 用户在大厅仓库换装 → WardrobeSync 的 send_depot_put_on_req Hook 已精确捕获
--   2. 退出对局后游戏会把角色 slot5 重置成默认值（如 1408079 → 1405770），
--      这不是用户的选择，captureSlots 会误写成配置
--   3. 后果：进第二次对局(含地铁)时，角色套上了错的 ID，看起来像 NPC
--   4. 用户主动换装已经 100% 被 WardrobeSync 覆盖，这里兜底捕获反而制造 bug
if e.SlotID == 5 then
    return
end

    if val > 0 and val ~= old then
    -- ★★★ 修复：头饰(3) / 眼罩(12) 捕获互斥 ★★★
    -- 游戏会把同一件头饰同时放到 slot 3 和 slot 12，这里只保留一个
    if e.SlotID == 12 then
        local hatVal = (API.GetRawSlot and API.GetRawSlot(3)) or 0
        if hatVal == val then
            -- 头饰已经用了这个 ID，眼罩跳过（避免写一次盘）
            return
        end
    elseif e.SlotID == 3 then
        local maskVal = (API.GetRawSlot and API.GetRawSlot(12)) or 0
        if maskVal == val then
            -- 头饰优先：清掉眼罩里重复的 ID
            if API.SetSlot then API.SetSlot(12, 0) end
        end
    end
    API.SetSlot(e.SlotID, val)
    changed = true
end
end
end
end)
end
    
    -- ★★★ 核心：保存完后，瞬间把新衣服同步给内存！让后台定时器无话可说！
    if changed and API.ApplyToGlobals then
        API.ApplyToGlobals()
    end
end



-- ★★★ 大厅换装 Hook：选完立即捕获写盘（替代 1.5 秒轮询）★★★
local captureWeapon, capturePet
local function installCaptureHook()
    local ch = getLobbyChar()
    if not ch or not slua.isValid(ch) then return false end
    local ad, comp = getSlotArray(ch)
    if not comp then return false end
    if comp.__wm_captureHooked then return true end

    local origBody = comp.OnRep_BodySlotStateChanged
if origBody then
    comp.OnRep_BodySlotStateChanged = function(self, ...)
        if origBody then origBody(self, ...) end
        -- ★ 延迟 0.5 秒等 SlotSyncData 同步完再捕获，防止读到旧值
        local tt = _G.Mytimer_ticker
        if tt then
            tt.AddTimer(0.5, function()
                if captureSlots then pcall(captureSlots) end
                if captureWeapon then pcall(captureWeapon) end
                if capturePet then pcall(capturePet) end
            end)
        else
            if captureSlots then pcall(captureSlots) end
            if captureWeapon then pcall(captureWeapon) end
            if capturePet then pcall(capturePet) end
        end
    end
end

    local origInit = comp.InitDepotCommonPutOn
    if origInit then
        comp.InitDepotCommonPutOn = function(self, ...)
            local r = origInit(self, ...)
            if captureSlots then pcall(captureSlots) end
            if captureWeapon then pcall(captureWeapon) end
            if capturePet then pcall(capturePet) end
            return r
        end
    end

    comp.__wm_captureHooked = true
    return true
end


-- ★ 抓一次武器皮肤 → 有变化立即写盘（G= 行）
-- 三路并行：① DataMgr 单把  ② 扫描 DataMgr 里的武器皮肤表  ③ 大厅角色身上的武器
captureWeapon = function()
    if type(DataMgr) ~= "table" then return end

    -- ① 单把当前选中的武器（大厅点一把枪会写这里）
    pcall(function()
        local wid = DataMgr.Weapon_ID
        local sid = DataMgr.Weapon_Skin_ResID
        if wid and sid and wid > 0 and sid > 0 then
            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
            if base and base > 0 and sid ~= base then
                API.SetWeapon(base, sid)
            end
        end
    end)

    -- ★ 功耗：原②全表扫描非常重，改为 30 秒才兜底跑一次
local _nowScan = os.clock()
-- ★性能：不在大厅不做 DataMgr 全表扇描
local _inLobbyScan = (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity())
if _inLobbyScan and _nowScan - _G.__perf.dataMgrScanAt >= 30 then
    _G.__perf.dataMgrScanAt = _nowScan
    pcall(function()
        for fieldName, fieldVal in pairs(DataMgr) do
            if type(fieldVal) == "table" then
                local name = tostring(fieldName):lower()
                if name:find("weapon", 1, true)
                   or name:find("skin", 1, true)
                   or name:find("gun", 1, true) then
                    for k, v in pairs(fieldVal) do
                        local wid = tonumber(k)
                        local sid = tonumber(v)
                        if wid and sid and wid > 0 and wid < 1000000
                           and sid > wid then
                            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
                            if base and base > 0 then
                                API.SetWeapon(base, sid)
                            end
                        end
                    end
                end
            end
        end
    end)
end

    -- ③ 兜底：大厅角色身上真有武器时
    local ch = getLobbyChar()
    if not ch or not slua.isValid(ch) then return end
    pcall(function()
        local w
        if ch.GetCurrentWeapon then w = ch:GetCurrentWeapon() end
        if not w and ch.CurrentWeapon then w = ch.CurrentWeapon end
        if not w or not slua.isValid(w) then return end

        local wid = 0
        if w.GetWeaponID then wid = w:GetWeaponID() or 0 end
        if wid <= 0 and w.GetItemDefineID then
            local d = w:GetItemDefineID()
            if d then wid = d.TypeSpecificID or 0 end
        end

        local sid = 0
        local arr = w.synData
        if arr and slua.isValid(arr) then
            local d = arr:Get(7)
            if d and slua.isValid(d) then
                sid = slua.IndexReference(d, 'defineID').TypeSpecificID or 0
            end
        end
        if wid > 0 and sid > 0 then
            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
            if base and base > 0 and sid ~= base then
                API.SetWeapon(base, sid)
            end
        end
    end)
end

    -- ★ 抓一次宠物（P= 行）
    capturePet = function()
        -- ★性能：不在大厅就不拿宠物模块，避免每次切页都 require
        if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then return end
        pcall(function()
            local MM = require("client.module_framework.ModuleManager")
            local lp = MM and MM.GetModule(MM.CommonModuleConfig.logic_pet)
            if lp and lp.GetEquipedPetInsID then
                local id = lp:GetEquipedPetInsID() or 0
                if id > 0 then API.SetPet(id) end
            end
        end)
    end



-- ========== 进对局：读取文件并刷新 ==========
local function applyToMatch()
    API.Load()             -- 重读文件
    API.ApplyToGlobals()   -- 注入内存

    -- ★★★ 进对局立即应用所有功能开关 ★★★
    pcall(ReadConfigFile)                          -- 重新读开关
    if _G.GameCameraView then pcall(_G.GameCameraView) end
    if _G.UpdateWeatherMode then pcall(_G.UpdateWeatherMode, _G.WeatherMode or 0) end
    if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
    if _G.ApplyPetSkinInGame then pcall(_G.ApplyPetSkinInGame) end
    if _G.GoldenLeavesTrail and _G.GoldenLeavesTrail.Apply then
        pcall(_G.GoldenLeavesTrail.Apply)
    end
    if _G.SetWeaponAnimation and _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        local wa = _G.DazhiMH_Config.Get("WEAPON_ANIM", 0) == 1
        pcall(_G.SetWeaponAnimation, wa)
    end
    -- ★★★ 立即应用结束 ★★★

    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return end
        local ch
        pcall(function() ch = pc:GetPlayerCharacterSafety() end)
        if not ch or not slua.isValid(ch) then return end

        -- ① 遍历背包所有武器 → 按 D.W 上主皮肤 + 配件
        pcall(function()
            local wm = ch:GetWeaponManager()
            if not wm or not slua.isValid(wm) then return end
            local list = wm:GetAllInventoryWeaponList(false)
            if not list or not slua.isValid(list) then return end
            for i = 0, list:Num() - 1 do
                local w = list:Get(i)
                if w and slua.isValid(w) then
                    local wid = w:GetWeaponID() or 0
                    if wid > 0 then
                        local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
                        local target = D.W[base]
                        if target and target > 0 then
                            local arr = w.synData
                            if arr and slua.isValid(arr) then
                                local d = arr:Get(7)
                                if d and slua.isValid(d) then
                                    local cur = slua.IndexReference(d, "defineID").TypeSpecificID
                                    if cur ~= target then
                                        slua.IndexReference(d, "defineID").TypeSpecificID = target
                                        arr:Set(7, d)
                                    end
                                end
                            end
                            if _G.apply_attachment then pcall(_G.apply_attachment, w, target) end
                            if w.DelayHandleAvatarMeshChanged then
                                pcall(function() w:DelayHandleAvatarMeshChanged() end)
                            end
                            if w.WeaponAvatarComponent and slua.isValid(w.WeaponAvatarComponent) then
                                pcall(function()
                                    if w.WeaponAvatarComponent.OnRep_AvatarChanged then
                                        w.WeaponAvatarComponent:OnRep_AvatarChanged()
                                    end
                                    if w.WeaponAvatarComponent.OnRep_SkinChanged then
                                        w.WeaponAvatarComponent:OnRep_SkinChanged()
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end)

        -- ② 角色槽位强制覆盖（Hook 式：先让原函数处理，再补漏 + 变化检测触发刷新）
pcall(function()
    -- 第一步：先让 equip_character_avatar 按全局变量去改
    -- 不改 ad，让它自己走"ItemId 不同 → 设置 + 刷新"的逻辑
    _G.__forceSkinRefresh = true
    if _G.equip_character_avatar then pcall(_G.equip_character_avatar, ch) end
    _G.__forceSkinRefresh = false

    -- 第二步：Hook 式补漏
    -- 对比全局变量与 ad 真实值，把没生效的槽位补上并强制刷新
    local ad = getSlotArray(ch)
    if not ad then return end

    -- 槽位 → 全局变量名映射（和 SLOT_GLOBAL 保持一致）
    local SLOT_VAR = {
    [2]  = "HairSkin",      -- ★ 补：头发
    [3]  = "HatSkin",
    [4]  = "FaceSkin",
    [12] = "MaskSkin",
    [5]  = "SuitSkin",
    [6]  = "PantSkin",
    [7]  = "ShoeSkin",
    [16] = "GlovesSkin",
    [11] = "ParachuteSkin", -- ★ 补：降落伞
    [15] = "GliderSkin",    -- ★ 补：滑翔翼
}

    local changed = false

    -- 第 1 步：遍历现有槽位，把值 Set 进去
for i = 0, ad:Num() - 1 do
    local e = ad:Get(i)
    if e then
        local varName = SLOT_VAR[e.SlotID]
        local target = varName and _G[varName]
                       
        if target and target > 0 and e.ItemId ~= target then
                e.ItemId = target
                ad:Set(i, e)
                changed = true
            end
        end
    end

    -- ★★★ 第 2 步：对不存在的槽位主动 Add ★★★
    -- 这一步是修复眼罩/口罩的关键
    for slot, varName in pairs(SLOT_VAR) do
        local target = _G[varName]
        if target and target > 0 then
            -- 检查 slot 是否已存在
            local found = false
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e and e.SlotID == slot then
                    found = true
                    break
                end
            end
            -- 不存在就添加
            if not found then
                ad:Add({ SlotID = slot, ItemId = target })
                changed = true
            end
        end
    end
    -- ★★★ 新增结束 ★★★

    -- 只有真的发生了变化才触发刷新
    -- 这样每局进对局只刷一次，不会每帧都刷 → 不卡
    if changed then
        -- ★ 再次调用 equip_character_avatar，确保新补上的头饰/眼罩/口罩等槽位被正确赋值
        _G.__forceSkinRefresh = true
        if _G.equip_character_avatar then pcall(_G.equip_character_avatar, ch) end
        _G.__forceSkinRefresh = false

        if ch.AvatarComponent2 and ch.AvatarComponent2.OnRep_BodySlotStateChanged then
            pcall(function() ch.AvatarComponent2:OnRep_BodySlotStateChanged() end)
        end
    end
end)
        if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end

        -- ③ 补刷（防模型异步重建覆盖）
        if _G.Mytimer_ticker then
            local t = _G.Mytimer_ticker
            for _, sec in ipairs({ 1.0, 2.5, 5.0, 8.0 }) do
                t.AddTimer(sec, function()
                    pcall(function()
                        API.ApplyToGlobals()
                        if _G.GameAvatarHandlerweapons then _G.GameAvatarHandlerweapons() end
                        if _G.GameAvatarHandlerplayers then _G.GameAvatarHandlerplayers() end                        
                    end)
                end)
            end
        end
    end

    -- ========== 初始化 ==========
    ensureFile()
    load()
    API.ApplyToGlobals()
    log("已加载, 路径=" .. PATH)

-- ========== 定时器 ==========
if _G.Mytimer_ticker then
_WK_T = _G.Mytimer_ticker
_WK_wasLobby = false

-- 进大厅：立即应用一次 + 延迟补刷多次（修复退出对局后发型被角色重建重置）
_WK_T.AddTimerLoop(1, function()
    local l = inLobby()
    if l and not _WK_wasLobby then
        _WK_wasLobby = true
        D._suppressUntil = 0
        if not (API.HasAnyConfig and API.HasAnyConfig()) then return end
        pcall(API.ApplyToLobby)

        -- ★★★ 关键修复 ★★★
        -- 退出对局回大厅时，游戏会异步重建大厅角色，把头发/脸型重置为默认。
        -- 这里在重建完成后延迟补刷几次，确保设置页配置的发型/脸型被重新写回。
        -- 安全性说明：
        --   1) ApplyToLobby 内部先 load() 重读文件，不会用旧值覆盖你在仓库换的衣服
        --      （仓库换装已被 WardrobeSync 写进 wumingking.h，load() 读到的是新值）
        --   2) 补刷只应用配置文件里的值，不扫描大厅换装，不写文件
        --   3) 只在"进入大厅那一刻"触发，之后不再补刷，不影响大厅手动操作
        -- 只补刷一次，避免角色反复重建导致大厅/仓库卡顿
_WK_T.AddTimer(1.5, function()
    if inLobby() then
        pcall(API.ApplyToLobby, true)  -- silent 模式，不重建骨骼网格
    end
end)
    elseif not l and _WK_wasLobby then
        _WK_wasLobby = false
    end
end, -1, 1)

-- ★ 大厅换装 Hook 检查：每 1 秒确认一次（角色重建后自动重挂）
_WK_T.AddTimerLoop(1, function()
    if not inLobby() then return end
    pcall(installCaptureHook)
end, -1, 1)

-- 兜底捕获：3 秒一次（Hook 失效时兜底，平时不触发）
_WK_T.AddTimerLoop(3, function()
    if not inLobby() then return end
    pcall(captureSlots)
    pcall(captureWeapon)
    pcall(capturePet)
end, -1, 1)
    -- ★★★ 关键修复结束 ★★★

_WK_wasInMatch = false
_WK_T.AddTimerLoop(1, function()
    local m = inMatch()
    if m and not _WK_wasInMatch then
        _WK_T.AddTimer(1.0, function()
            pcall(applyToMatch)
        end)
    end
    _WK_wasInMatch = m
end, -1, 1)
end
end       



-- ============================================================
-- ★★★ 设置页：读取/修改 wumingking.h ★★★
-- ============================================================
do
    _G.__DazhiMH_CachedCustomPages = nil

    local function getAliasMap()
    local um = _G.UIManager
    if not (um and um.UI_Config) then
        local ok, m = pcall(require, "client.slua_ui_framework.manager")
        if ok then um = m end
    end
    if um and um.UI_Config then
        local c = um.UI_Config
        if c.Setting_Title and c.Setting_Spacer and c.Setting_Option_OpenWindow and c.Setting_Option_Slider then
            local am = {
                Title = c.Setting_Title,
                Spacer = c.Setting_Spacer,
                OpenWindow = c.Setting_Option_OpenWindow,
                Slider = c.Setting_Option_Slider,
                Switcher = c.Setting_Option_Switcher,
            }
            if not am.Switcher then
                local ok2, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
                if ok2 and AliasMap then am.Switcher = AliasMap.Switcher end
            end
            return am
        end
    end
    return nil
end

    local WK_Reg_Cache = {}
local function Reg(text)
    if not text then return 0 end
    if WK_Reg_Cache[text] then return WK_Reg_Cache[text] end

    local id = _G.__WK_NextLocId or 897000000
    id = id + 1
    _G.__WK_NextLocId = id
    if LocUtil and type(LocUtil.GetLocalizeResStr) == "function" then
        if not _G.__WK_LocPatched then
            _G.__WK_LocPatched = true
            local orig = LocUtil.GetLocalizeResStr
            LocUtil.GetLocalizeResStr = function(i)
                local m = _G.__WK_LocMap
                if m and m[i] then return m[i] end
                return orig(i)
            end
        end
        _G.__WK_LocMap = _G.__WK_LocMap or {}
        _G.__WK_LocMap[id] = text
    end
    WK_Reg_Cache[text] = id
    return id
end

-- 人物套装 Tab（只保留：宠物、防弹衣、头盔、背包、飞行器/滑翔翼、降落伞）
if _G.SuitSettingTab then
    local SST = _G.SuitSettingTab

-- 只保留发型、降落伞、滑翔翼（口罩/衣服/套装走大厅仓库勾选自动保存）
local INPUT_ITEMS = {
    { label = "发型 / Hair",           slot = 2 },
    { label = "降落伞 / Parachute",    slot = 11 },
    { label = "滑翔翼 / Glider",       slot = 15 },
}

    SST.BuildStack = function()
        local AM = getAliasMap(); if not AM then return nil end
        local C = _G.Wumingking
        local stack = {}

        -- ========== 宠物 ==========
table.insert(stack, { UI = AM.Title, Text = Reg("宠物 / Pet") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

local petList = SST.PET_SKIN_LIST or {}
local petCount = (#petList > 0 and #petList or 1)

-- ========== 宠物滑块（保存的是真实ID，下次启动按ID反查索引定位） ==========
table.insert(stack, {
    Key = "WK_PetSlider",
    UI = AM.Slider,
    Text = Reg("宠物皮肤 / Pet Skin"),
    Help = "滑动切换宠物（共 " .. #petList .. " 种）\n保存后下次启动自动定位",
    Min = 1,
    Max = petCount,
    IsPercent = false,
    GetFunc = function()
        -- 1) 从 wumingking.h 读真实宠物ID（D.P）
        local petId = 0
        if _G.Wumingking and _G.Wumingking.GetPet then
            petId = _G.Wumingking.GetPet() or 0
        end

        -- 2) 反查索引 → 定位滑块
        if petId and petId > 0 then
            for i, id in ipairs(petList) do
                if id == petId then
                    return i
                end
            end
        end

        -- 3) 兜底：用内存里的索引
        local idx = _G.PetSkinMapIndex
        if type(idx) ~= "number" or idx < 1 then idx = 1 end
        idx = math.floor(idx)
        if idx < 1 then idx = 1 end
        if idx > petCount then idx = petCount end
        return idx
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 1)
        if idx < 1 then idx = 1 end
        if idx > petCount then idx = petCount end
        local petId = petList[idx]

        _G.PetSkinMapIndex = idx
        _G.PetSkin = petId

        -- ★ 只保存真实ID到 wumingking.h（不保存索引，避免两套数据打架）
        if _G.Wumingking and _G.Wumingking.SetPet then
            _G.Wumingking.SetPet(petId)
        end

        if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
        if _G.ApplyPetSkinInGame then pcall(_G.ApplyPetSkinInGame) end

        print("[Pet] 切换到 ID=" .. tostring(petId) .. " (索引 " .. tostring(idx) .. ")")
        return true
    end
})

-- ========== 宠物ID 只读显示框 ==========
table.insert(stack, {
    Key = "WK_PetIDDisplay",
    UI = AM.OpenWindow,
    Text = Reg("  └ 当前宠物ID / Current Pet ID"),
    Help = "只读，点开可查看当前生效的宠物ID",
    GetFunc = function()
        local petId = 0
        if _G.Wumingking and _G.Wumingking.GetPet then
            petId = _G.Wumingking.GetPet() or 0
        end
        if petId and petId > 0 then
            return tostring(petId)
        end
        return "未设置"
    end,
    SetFunc = function()
        -- 只读弹窗，可看可复制，不做任何修改
        if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
        local cur = 0
        if _G.Wumingking and _G.Wumingking.GetPet then
            cur = _G.Wumingking.GetPet() or 0
        end
        _G.DazhiMH_Config.ShowNumberInputPopup({
            title = "当前宠物ID（只读，请用上方滑块修改）",
            value = cur, min = 0, max = 9999999999,
            refreshKey = "WK_PetIDDisplay",
            onConfirm = function()
                -- 什么都不做（只读）
            end
        })
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ========== 发型 / 脸型 / 降落伞 / 滑翔翼 ==========
table.insert(stack, { UI = AM.Title, Text = Reg("发型 / 配件") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

for _, item in ipairs(INPUT_ITEMS) do
    local slotId = item.slot
    local key = "WK_Outfit_" .. slotId

    table.insert(stack, {
        Key = key, UI = AM.OpenWindow, Text = Reg(item.label),
        GetFunc = function()
            local v = (C and C.GetSlot and C.GetSlot(slotId)) or 0
            if v and v > 0 then return tostring(v) end
            return "未设置"
        end,
        SetFunc = function()
            if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
            local cur = (C and C.GetSlot and C.GetSlot(slotId)) or 1
            _G.DazhiMH_Config.ShowNumberInputPopup({
                title = item.label .. " (输入0=用配置保存的值)",
                value = cur, min = 0, max = 9999999999,
                refreshKey = key,
                onConfirm = function(v)
                    v = math.floor(tonumber(v) or 0)
                    if v < 0 then v = 0 end

                    -- ★ 降落伞/滑翔翼：0 强制用默认值（100% 安装）
                    if slotId == 11 and v <= 0 then v = 1401469 end
                    if slotId == 15 and v <= 0 then v = 4151133 end

                    if v == 0 then
                        if C and C.Load then C.Load() end
                        if C and C.ApplyToGlobals then C.ApplyToGlobals() end
                    else
                        if C and C.SetSlot then C.SetSlot(slotId, v) end
                        if C and C.ApplyToGlobals then C.ApplyToGlobals() end
                    end

                    pcall(function()
                        if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                            _G.Wumingking.ApplyToLobby()
                        end
                    end)
                end
            })
        end
    })
    table.insert(stack, { UI = AM.Spacer, Height = 5 })
end

-- ==================== ★★★ 车库展示车系选择 ★★★ ====================
table.insert(stack, { UI = AM.Spacer, Height = 15 })
table.insert(stack, { UI = AM.Title, Text = Reg("车库展示车系 / Garage Brand") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "GarageBrandMode",
    UI = AM.Switcher,
    Text = Reg("选择默认展示的车系"),
    Help = "选择进入车库主题时展示的系列\n1=法拉利系列\n2=布加迪系列\n3=兰博基尼系列",
    SwitcherText = { Reg("法拉利"), Reg("布加迪"), Reg("兰博基尼") },
    SwitcherValue = { 1, 2, 3 },
    GetFunc = function()
        return DazhiMH_Config.Get("GARAGE_BRAND", 1)
    end,
    SetFunc = function(_, value)
        value = tonumber(value) or 1
        DazhiMH_Config.Set("GARAGE_BRAND", value)
        
        -- 立刻强制刷新车库模型
        pcall(function()
            local MM = require("client.module_framework.ModuleManager")
            local mgr = MM.GetModule(MM.LobbyModuleConfig.ThemeVehicleManager)
            if mgr then
                if mgr._ShowSelfVehicle then mgr:_ShowSelfVehicle() end
                if mgr.OnVehicleChange then mgr:OnVehicleChange() end
            end
        end)
        return true
    end
})
table.insert(stack, { UI = AM.Spacer, Height = 15 })


-- ==================== 手套美化 / Gloves ====================
table.insert(stack, { UI = AM.Title, Text = Reg("手套美化 / Gloves") })
table.insert(stack, { UI = AM.Spacer, Height = 6 })

table.insert(stack, {
    Key = "WK_GlovesInput",
    UI = AM.OpenWindow,
    Text = Reg("手套皮肤 / Gloves"),
    Help = "1=隐藏手套(450001)\n2=冰霜(452001)\n3=水墨(452002)\n4=流沙(452003)\n5=蛛丝(452004)\n6=摆荡(452105)\n输入0=不修改\n输入其他数字=直接使用该ID",
    GetFunc = function()
        local v = (C and C.GetSlot and C.GetSlot(16)) or 0
        -- 如果内部保存的是隐藏手套ID，UI上直接显示“未设置”
        if v == 450001 or v == 0 then
            return "未设置"
        end
        return tostring(v)
    end,
    SetFunc = function()
        if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
        local cur = (C and C.GetSlot and C.GetSlot(16)) or 0
        if cur == 450001 then cur = 1 end -- 如果当前是隐藏，弹窗里默认显示 1
        
        _G.DazhiMH_Config.ShowNumberInputPopup({
            title = "输入 1~6 快捷选择，或填入手套ID\n(1=隐藏, 2=冰霜, 3=水墨, 4=流沙, 5=蛛丝, 6=摆荡)",
            value = cur, min = 0, max = 9999999999,
            refreshKey = "WK_GlovesInput",
            onConfirm = function(v)
                v = math.floor(tonumber(v) or 0)
                
                -- ★ 快捷代码映射表
                local GLOVE_MAP = {
                    [1] = 450001, -- 隐藏手套/无手套模型
                    [2] = 452001,
                    [3] = 452002,
                    [4] = 452003,
                    [5] = 452004,
                    [6] = 452105,
                }
                
                local targetId = v
                if GLOVE_MAP[v] then
                    targetId = GLOVE_MAP[v]
                end
                
                -- 输入0同样代表隐藏手套（保底）
                if v == 0 then
                    targetId = 450001
                end

                -- 1. 保存至配置并应用
                if C and C.SetSlot then C.SetSlot(16, targetId) end
                _G.GlovesSkin = targetId

                if C and C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
                pcall(function()
                    if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                        _G.Wumingking.ApplyToLobby()
                    end
                end)
                if _G.GameAvatarHandlerplayers then
                    pcall(_G.GameAvatarHandlerplayers)
                end
            end
        })
    end
})

table.insert(stack, {
    Key = "WK_GlovesHideOnGun",
    UI = AM.Switcher,
    Text = Reg("拿枪隐藏手套 / Hide Gloves on Gun"),
    Help = "开启后，拿枪时自动隐藏手套，收枪/空手时恢复显示",
    GetFunc = function()
        return (DazhiMH_Config.Get("GLOVES_HIDE_ON_GUN", 0) == 1)
    end,
    SetFunc = function(_, value)
        DazhiMH_Config.Set("GLOVES_HIDE_ON_GUN", value and 1 or 0)
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
        return true
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ==================== 功能开关 / Functional Toggles ====================
table.insert(stack, { UI = AM.Title, Text = Reg("功能开关 / Functional Toggles") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "WK_GrenadeFastRefresh",
    UI = AM.Switcher,
    Text = Reg("手雷极速刷新 / Grenade Fast Refresh"),
    Help = "开启后，手雷皮肤刷新频率极大幅度提升\n(注意：可能会增加一点耗电)",
    GetFunc = function() return DazhiMH_Config.Get("GRENADE_FAST_REFRESH", 0) == 1 end,
    SetFunc = function(_, value) 
        DazhiMH_Config.Set("GRENADE_FAST_REFRESH", value and 1 or 0) 
        return true 
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "WK_WeaponFastRefresh",
    UI = AM.Switcher,
    Text = Reg("枪械/配件极速刷新 / Weapon Fast Refresh"),
    Help = "开启后，枪械和配件刷新间隔缩短至 1 秒\n关闭则保持默认 1.5 秒",
    GetFunc = function() return DazhiMH_Config.Get("WEAPON_FAST_REFRESH", 0) == 1 end,
    SetFunc = function(_, value) 
        DazhiMH_Config.Set("WEAPON_FAST_REFRESH", value and 1 or 0) 
        return true 
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "WK_WeaponBackRefresh",
    UI = AM.Switcher,
    Text = Reg("无手持枪械刷新 / Back Weapon Refresh"),
    Help = "开启后，捡起放在背上的枪也会自动刷皮肤\n关闭则只在拿在手上时才刷新",
    GetFunc = function() return DazhiMH_Config.Get("WEAPON_BACK_REFRESH", 0) == 1 end,
    SetFunc = function(_, value) 
        DazhiMH_Config.Set("WEAPON_BACK_REFRESH", value and 1 or 0) 
        return true 
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== 背包开关（开=450001，关=按配置刷新） ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("背包皮肤 / Backpack") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_BackpackSwitch",
            UI = AM.Switcher,
            Text = Reg("背包皮肤 / Backpack"),
            Help = "开启：所有等级背包显示 450001 皮肤\n关闭：按配置刷新",
            GetFunc = function()
                return _G.Backpack1Skin == 450001 and _G.Backpack2Skin == 450001
                    and _G.Backpack3Skin == 450001 and _G.Backpack4Skin == 450001
                    and _G.Backpack5Skin == 450001 and _G.Backpack6Skin == 450001
            end,
            SetFunc = function(_, value)
                if value then
                    for i = 1, 6 do _G["Backpack" .. i .. "Skin"] = 450001 end
                    if C and C.SetSlot then C.SetSlot(8, 450001) end
                else
                    local cfg = _G.DazhiMH_Config
                    local firstVal = 0
                    for i = 1, 6 do
                        local v = (cfg and cfg.Get and cfg.Get("BACKPACK" .. i, 0)) or 0
                        _G["Backpack" .. i .. "Skin"] = v
                        if firstVal == 0 and v > 0 then firstVal = v end
                    end
                    if C and C.SetSlot then C.SetSlot(8, firstVal) end
                end
                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })

        table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== 头盔开关（开=450001，关=按配置刷新） ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("头盔皮肤 / Helmet") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_HelmetSwitch",
            UI = AM.Switcher,
            Text = Reg("头盔皮肤 / Helmet"),
            Help = "开启：所有等级头盔显示 450001 皮肤\n关闭：按配置刷新",
            GetFunc = function()
                return _G.Helmet1Skin == 450001 and _G.Helmet2Skin == 450001
                    and _G.Helmet3Skin == 450001 and _G.Helmet4Skin == 450001
                    and _G.Helmet5Skin == 450001 and _G.Helmet6Skin == 450001
            end,
            SetFunc = function(_, value)
                if value then
                    for i = 1, 6 do _G["Helmet" .. i .. "Skin"] = 450001 end
                    if C and C.SetSlot then C.SetSlot(9, 450001) end
                else
                    local cfg = _G.DazhiMH_Config
                    local firstVal = 0
                    for i = 1, 6 do
                        local v = (cfg and cfg.Get and cfg.Get("HELMET" .. i, 0)) or 0
                        _G["Helmet" .. i .. "Skin"] = v
                        if firstVal == 0 and v > 0 then firstVal = v end
                    end
                    if C and C.SetSlot then C.SetSlot(9, firstVal) end
                end
                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })

        table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== 防弹衣开关（例外：关=恢复原状） ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("防弹衣皮肤 / Armor") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_ArmorSwitch",
            UI = AM.Switcher,
            Text = Reg("防弹衣皮肤 / Armor"),
            Help = "开启：所有等级防弹衣显示 450001 皮肤\n关闭：恢复原状",
            GetFunc = function()
                return _G.Armor1Skin == 450001 and _G.Armor2Skin == 450001
                    and _G.Armor3Skin == 450001 and _G.Armor4Skin == 450001
                    and _G.Armor5Skin == 450001 and _G.Armor6Skin == 450001
            end,
            SetFunc = function(_, value)
                if value then
                    for i = 1, 6 do _G["Armor" .. i .. "Skin"] = 450001 end
                    if C and C.SetSlot then C.SetSlot(10, 450001) end
                else
                    -- 防弹衣例外：直接恢复原状（清 0）
                    for i = 1, 6 do _G["Armor" .. i .. "Skin"] = 0 end
                    if C and C.SetSlot then C.SetSlot(10, 0) end
                end
                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })

        -- ========== ⚠ 清空配置按钮 ==========
        table.insert(stack, { UI = AM.Spacer, Height = 20 })
        table.insert(stack, { UI = AM.Title, Text = Reg("⚠ 危险操作 / Danger Zone") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_ClearAll",
            UI = AM.OpenWindow,
            Text = Reg("清空所有配置 / Clear All"),
            Help = "清空所有已保存的皮肤配置（衣服/套装/头饰/口罩/武器/宠物/载具/功能开关）\n警告：不可恢复！",
            GetFunc = function()
                return "点击清空"
            end,
            SetFunc = function()
                if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
                _G.DazhiMH_Config.ShowNumberInputPopup({
                    title = "确认清空所有配置？输入 1 确认，其它值取消",
                    value = 0, min = 0, max = 1,
                    refreshKey = "WK_ClearAll",
                    onConfirm = function(v)
                        if tonumber(v) == 1 then
                            if _G.Wumingking and _G.Wumingking.ClearAll then
                                _G.Wumingking.ClearAll()
                            end
                        else
                            print("[Wumingking] 用户取消清空")
                        end
                    end
                })
            end
        })

        return stack
    end
end

    _G.__DazhiMH_CachedCustomPages = nil
    _G.__DazhiMH_SettingMainPatched = nil
    _G.__DazhiMH_SettingHooksInstalled = nil
end


-- ==================== 头发锁死守护（防重建丢失） ====================
-- 只要 _G.HairSkin > 0，无论角色怎么重建/换装/进出对局，
-- 都强制保持配置的头发。只有改设置才能更换。
-- 核心思路：Hook OnRep_BodySlotStateChanged → 重建完成立刻修复
pcall(function()
    if _G.__HairGuardInstalled then return end
    _G.__HairGuardInstalled = true

    local HAIR_SLOT = 2

    local function getComp(target)
        if not target or not slua.isValid(target) then return nil end
        local comp = target.AvatarComponent2
        if comp and slua.isValid(comp) then return comp end
        pcall(function()
            if target.getAvatarComponent2 then
                local c = target:getAvatarComponent2()
                if c and slua.isValid(c) then comp = c end
            end
        end)
        return comp
    end

    local function fixHair(comp)
    -- ★★★ 核心修复：如果正在切换大厅主题或刚退对局，跳过修复，避免打断游戏原生重建模型 ★★★
    if _G.__IsThemeSwitching or _G.__justExitedMatch then return end
    if not comp or not slua.isValid(comp) then return end
    local hair = _G.HairSkin or 0

        local ad
        pcall(function()
            local nad = comp.NetAvatarData
            if nad and slua.isValid(nad) then ad = nad.SlotSyncData end
        end)
        if not ad then return end

        local idx, cur = -1, 0
        for i = 0, ad:Num() - 1 do
            local e = ad:Get(i)
            if e and e.SlotID == HAIR_SLOT then idx = i; cur = e.ItemId or 0; break end
        end

        if idx < 0 then
            ad:Add({ SlotID = HAIR_SLOT, ItemId = hair })
        elseif cur == hair then
            return   -- 已经对了，不重复触发
        else
            local e = ad:Get(idx)
            e.ItemId = hair
            ad:Set(idx, e)
        end

        -- 通知重建（用 flag 避免和 Hook 互递归）
        comp.__hairGuardSuppress = true
        pcall(function()
            if comp.OnRep_BodySlotStateChanged then
                comp.OnRep_BodySlotStateChanged(comp)
            end
        end)
        comp.__hairGuardSuppress = false
        print("[HairGuard] 修复头发 → " .. tostring(hair))
    end

    local function hookComp(target, tag)
        local comp = getComp(target)
        if not comp then return false end
        if comp.__hairGuardHooked then
            -- 已 hook，顺手修复一次
            pcall(fixHair, comp)
            return true
        end
        comp.__hairGuardHooked = true

        local orig = comp.OnRep_BodySlotStateChanged
if type(orig) == "function" then
    comp.OnRep_BodySlotStateChanged = function(self, ...)
        if orig then orig(self, ...) end
        -- 关键：只有不是我们自己在 fixHair 内部调用时才修复，避免死循环
        if not self.__hairGuardSuppress then
            -- ★★★ 核心修复：增加 0.5 秒防抖延迟，等待模型骨骼彻底加载完再修复 ★★★
            if self.__hairGuardTimer then
                pcall(function() _G.Mytimer_ticker.RemoveTimer(self.__hairGuardTimer) end)
            end
            if _G.Mytimer_ticker then
                self.__hairGuardTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
                    if slua.isValid(self) and not self.__hairGuardSuppress then
                        pcall(fixHair, self)
                    end
                end)
            else
                pcall(fixHair, self)
            end
        end
    end
            print("[HairGuard] Hook OnRep: " .. tag)
            pcall(fixHair, comp)
            return true
        end
        return false
    end

    local function tryHookAll()
        -- 大厅角色
        pcall(function()
            local LAM = require("client.logic.avatar.LobbyAvatarManager")
            for _, v in pairs(LAM.playerList or {}) do
                if type(v) == "userdata" and slua.isValid(v) then
                    hookComp(v, "大厅")
                    break
                end
            end
        end)
        -- 对局角色
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if pc and slua.isValid(pc) then
                local ch = pc:GetPlayerCharacterSafety()
                if ch and slua.isValid(ch) then
                    hookComp(ch, "对局")
                end
            end
        end)
    end

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(1.5, tryHookAll)
        -- 每 1 秒重挂一次（角色重建后 Hook 会丢，需要重新挂到新组件上）
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(tryHookAll)
        end, -1, 1)
    else
        tryHookAll()
    end

    print("[HairGuard] 头发锁死守护已启动")
end)


-- ============================================================
-- ★★★ 大厅主题自动刷新（HallThemeSync v2 修复版）★★★
-- 修复：
--   ① 路径优先取 wumingking.h 实际路径，避免多包名写错文件
--   ② 写盘前校验文件存在，文件不存在不创建（防止清空配置）
--   ③ ProcPutOnHook 同时从【形参】和【self 字段】读，取第一个有效值
--   ④ 保存循环只在锁期外捕获"游戏内主动切换"，不覆盖用户期望值
--   ⑤ 用户操作锁从 10 秒 → 30 秒，防止异步回弹期间被覆盖
-- ============================================================
_G.HallThemeSync = _G.HallThemeSync or {}
do
    local HTS = _G.HallThemeSync
    local KEY = "BACKGROUND"
    local KEY_INST = "BACKGROUND_INST"

    -- ========== 状态变量 ==========
    local autoApplyTargetItem = 0
    local autoApplyTargetInst = 0
    local _inLobby = false
    local _lastSavedItem = -1
    local _lastForceApplyAt = 0
    local _expectedItemId = 0
    local _expectedInstId = 0
    local _userChangeLockUntil = 0

    -- ★★★ 修复 ①：路径优先用 Wumingking 实际路径 ★★★
    local function GetWuming()
        -- 1) Wumingking 已初始化（最准，按当前包名定位）
        local W = _G.Wumingking
        if W and type(W.Path) == "string" and W.Path ~= "" then
            return W.Path
        end
        -- 2) 动态按当前包名定位
        if _G.GetCurrentWumingPath then
            local p = _G.GetCurrentWumingPath()
            if p then return p end
        end
        -- 3) 兜底：遍历（可能写错文件，但至少不是 nil）
        local OBB_DIRS = {
            "/storage/emulated/0/Android/obb/com.tencent.ig/",
            "/storage/emulated/0/Android/obb/com.pubg.krmobile/",
            "/storage/emulated/0/Android/obb/com.vng.pubgmobile/",
            "/storage/emulated/0/Android/obb/com.rekoo.pubgm/",
            "/storage/emulated/0/Android/obb/com.pubg.imobile/",
        }
        for _, d in ipairs(OBB_DIRS) do
            local f = io.open(d .. "wumingking.h", "r")
            if f then f:close(); return d .. "wumingking.h" end
        end
        return OBB_DIRS[1] .. "wumingking.h"
    end

    local function GetThemeMod()
        local ok, m = pcall(require, "client.logic.lobby.hall_theme_utils")
        if ok and m then return m end
    end

    local function ReadKey(k)
        local f = io.open(GetWuming(), "r")
        if not f then return 0 end
        local val = 0
        for line in f:lines() do
            local kk, vv = line:match("^%s*([%w_]+)%s*=%s*(%d+)")
            if kk == k then val = tonumber(vv) or 0 end
        end
        f:close()
        return val
    end

    -- ★★★ 修复 ②：文件不存在就跳过，绝不创建只含 BACKGROUND 的空文件 ★★★
    local function WriteKey(k, v)
        v = math.floor(tonumber(v) or 0)
        local p = GetWuming()
        local probe = io.open(p, "r")
        if not probe then
            -- 文件不存在 → 说明 Wumingking 还没初始化好，本次跳过
            print("[HallThemeSync] WARN: 配置文件不存在，跳过写入 " .. k .. "=" .. v)
            return false
        end
        local lines, replaced = {}, false
        for line in probe:lines() do
            local kk = line:match("^%s*([%w_]+)%s*=")
            if kk == k then
                lines[#lines+1] = k .. "=" .. tostring(v)
                replaced = true
            else
                lines[#lines+1] = line
            end
        end
        probe:close()
        if not replaced then lines[#lines+1] = k .. "=" .. tostring(v) end
        local w = io.open(p, "w")
        if not w then return false end
        w:write(table.concat(lines, "\n") .. "\n")
        w:close()
        return true
    end

    function HTS.ReadSaved()       return ReadKey(KEY) end
    function HTS.WriteSaved(id)    return WriteKey(KEY, id) end
    function HTS.ReadSavedInst()   return ReadKey(KEY_INST) end
    function HTS.WriteSavedInst(v) return WriteKey(KEY_INST, v) end

    -- ========== 安装 Hook ==========
    local function InstallHooks()
        local m = GetThemeMod()
        if not m then return false end

        if not m._HookedGetCurShow and type(m.GetCurShowThemeItemId) == "function" then
            m._origGetCurShow = m.GetCurShowThemeItemId
            m.GetCurShowThemeItemId = function(self, ...)
                if autoApplyTargetItem > 0 then
                    return autoApplyTargetItem
                end
                return m._origGetCurShow(self, ...)
            end
            m._HookedGetCurShow = true
        end

        if not m._HookedGetInst and type(m.GetThemeInstId) == "function" then
            m._origGetInst = m.GetThemeInstId
            m.GetThemeInstId = function(self, ...)
                if autoApplyTargetInst > 0 then
                    return autoApplyTargetInst
                end
                return m._origGetInst(self, ...)
            end
            m._HookedGetInst = true
        end

        -- ★★★ 修复 ③：ProcPutOnHallTheme 从形参 + self 两边读 ★★★
        if not m._HookedProcPutOn and type(m.ProcPutOnHallTheme) == "function" then
            m._origProcPutOn = m.ProcPutOnHallTheme
            m.ProcPutOnHallTheme = function(self, ...)
                -- ForceApply 内部调用 → 直接透传（避免递归触发保存）
                if autoApplyTargetItem > 0 then
                    return m._origProcPutOn(self, ...)
                end

                -- 从形参里翻 itemId / instId（支持 number / table 两种形态）
                local args = { n = select("#", ...), ... }
                local wantItem, wantInst = 0, 0
                for i = 1, args.n do
                    local v = args[i]
                    if type(v) == "number" and v > 0 then
                        if wantItem == 0 then wantItem = v
                        elseif wantInst == 0 then wantInst = v end
                    elseif type(v) == "table" then
                        local a = tonumber(v.itemId or v.themeItemId or v.homeThemeItemId or v.id)
                        local b = tonumber(v.instId or v.themeInstId or v.homeThemeInstId)
                        if a and a > 0 and wantItem == 0 then wantItem = a end
                        if b and b > 0 and wantInst == 0 then wantInst = b end
                    end
                end

                -- 形参没给 → 读 self 字段
                if wantItem == 0 then
                    wantItem = tonumber(self.homeThemeItemId) or 0
                end
                if wantInst == 0 then
                    wantInst = tonumber(self.homeThemeInstId) or 0
                end

                local ret = m._origProcPutOn(self, ...)

                if wantItem > 0 then
                    _expectedItemId = wantItem
                    _expectedInstId = wantInst
                    _userChangeLockUntil = os.clock() + 30   -- ★ 锁 30 秒
                    _lastSavedItem = wantItem
                    _lastForceApplyAt = os.clock()
                    HTS.WriteSaved(wantItem)
                    if wantInst > 0 then HTS.WriteSavedInst(wantInst) end
                    print(string.format("[HallThemeSync] 用户应用主题: item=%d inst=%d（锁定30秒）",
                        wantItem, wantInst))
                else
                    -- ★ 兜底：hook 没拿到值时，延迟 0.3 秒后再读 self 字段
                    local tt = _G.Mytimer_ticker
                    if tt and tt.AddTimer then
                        tt.AddTimer(0.3, function()
                            local m2 = GetThemeMod()
                            if not m2 then return end
                            local it = tonumber(m2.homeThemeItemId) or 0
                            local ins = tonumber(m2.homeThemeInstId) or 0
                            if it > 0 and it ~= _lastSavedItem then
                                _expectedItemId = it
                                _expectedInstId = ins
                                _userChangeLockUntil = os.clock() + 30
                                _lastSavedItem = it
                                _lastForceApplyAt = os.clock()
                                HTS.WriteSaved(it)
                                if ins > 0 then HTS.WriteSavedInst(ins) end
                                print(string.format("[HallThemeSync] 兜底延迟保存: item=%d", it))
                            end
                        end)
                    end
                end
                return ret
            end
            m._HookedProcPutOn = true
        end

        return true
    end

    -- 进大厅恢复上次保存的主题（不涉及用户操作）
    function HTS.ForceApply()
        local m = GetThemeMod()
        if not m then return end
        local targetItem = HTS.ReadSaved()
        local targetInst = HTS.ReadSavedInst()
        if targetItem <= 0 then return end

        local cur = tonumber(m.homeThemeItemId) or 0
        if cur == targetItem then return end

        autoApplyTargetItem = targetItem
        autoApplyTargetInst = targetInst
        pcall(function()
            if m.ProcPutOnHallTheme then
                m:ProcPutOnHallTheme()
            end
        end)
        autoApplyTargetItem = 0
        autoApplyTargetInst = 0
        m.homeThemeItemId = targetItem
        if targetInst > 0 then
            m.homeThemeInstId = targetInst
        end
        _lastForceApplyAt = os.clock()
    end

    local function Attach()
        local t = _G.Mytimer_ticker
        if not t then
            local ok, tk = pcall(require, "common.time_ticker")
            if ok then t = tk end
        end
        if not t or not t.AddTimerLoop then return false end

        if not InstallHooks() then
            t.AddTimer(2, InstallHooks)
            t.AddTimer(5, InstallHooks)
            t.AddTimer(10, InstallHooks)
        end

        -- ========== 进大厅检测 + 恢复 ==========
        t.AddTimerLoop(1, function()
            pcall(function()
                local curInLobby = GameStatus and GameStatus.IsInLobbyOrMainCity
                    and GameStatus.IsInLobbyOrMainCity() == true

                if curInLobby and not _inLobby then
                    _inLobby = true
                    _lastSavedItem = -1
                    _expectedItemId = 0
                    _expectedInstId = 0
                    _userChangeLockUntil = 0

                    for _, delay in ipairs({0.5, 1.5, 3.0, 5.0, 8.0}) do
                        t.AddTimer(delay, function()
                            if os.clock() < _userChangeLockUntil then return end
                            local m = GetThemeMod()
                            if m then
                                local target = HTS.ReadSaved()
                                if target > 0 and tonumber(m.homeThemeItemId) ~= target then
                                    pcall(HTS.ForceApply)
                                end
                            end
                        end)
                    end
                elseif not curInLobby and _inLobby then
                    _inLobby = false
                end
            end)
        end, -1, 1)

        -- ========== 守护循环（1.5 秒）==========
        t.AddTimerLoop(1.5, function()
            pcall(function()
                if not _inLobby then return end
                if os.clock() < _userChangeLockUntil then return end   -- 用户操作锁期内不动

                local m = GetThemeMod()
                if not m then return end

                local target = _expectedItemId
                if target <= 0 then target = HTS.ReadSaved() end
                if target <= 0 then return end

                local cur = tonumber(m.homeThemeItemId) or 0
                if cur == target then return end

                local now = os.clock()
                if now - _lastForceApplyAt > 3.0 then
                    m.homeThemeItemId = target
                    local wantInst = _expectedInstId
                    if wantInst <= 0 then wantInst = HTS.ReadSavedInst() end
                    if wantInst > 0 then m.homeThemeInstId = wantInst end
                    _lastForceApplyAt = now
                    print(string.format("[HallThemeSync] 守护: 被回弹 → 强制改回 item=%d（静默）", target))
                end
            end)
        end, -1, 1)

        -- ========== 保存循环（1 秒）—— 只捕获"游戏内主动切换" ==========
        t.AddTimerLoop(1, function()
            pcall(function()
                if not _inLobby then return end
                if os.clock() < _userChangeLockUntil then return end

                local m = GetThemeMod()
                if not m then return end
                local item = tonumber(m.homeThemeItemId) or 0
                local inst = tonumber(m.homeThemeInstId) or 0

                -- ★ 关键修复：只保存"游戏字段变了 + 和期望不一样 + 不是被打回"
                --   如果 item 和 _expectedItemId 一样 → 是守护循环刚改回去的，不重复保存
                --   如果 item 和 _lastSavedItem 一样 → 没变化，不重复保存
                if item > 0 and item ~= _lastSavedItem and item ~= _expectedItemId then
                    -- 只在游戏字段真的变了（说明用户又切换了主题）时才写盘
                    HTS.WriteSaved(item)
                    if inst > 0 then HTS.WriteSavedInst(inst) end
                    _expectedItemId = item
                    _expectedInstId = inst
                    _lastSavedItem = item
                    print(string.format("[HallThemeSync] 捕获主题变化: item=%d", item))
                end
            end)
        end, -1, 1)
        return true
    end

    if not Attach() then
        local tries = 0
        local function Retry()
            tries = tries + 1
            if Attach() then return end
            if tries < 30 then
                local ok, tk = pcall(require, "common.time_ticker")
                if ok and tk and tk.AddTimer then tk.AddTimer(1, Retry) end
            end
        end
        Retry()
    end
end


-- ============================================================
-- ★★★ V8: 大厅武器皮肤（原版 Hook 版）★★★
-- ============================================================
pcall(function()
    local LAM = require("client.logic.avatar.LobbyAvatarManager")
    if not LAM or type(LAM.EquipWeapon) ~= "function" then return end

    -- 只 Hook 一次
    if rawget(LAM, "__wmEqOrig") == nil then
        rawset(LAM, "__wmEqOrig", LAM.EquipWeapon)
    end
    local origFn = rawget(LAM, "__wmEqOrig")

    local function GetSavedSkin(baseWid)
        if _G.Wumingking and _G.Wumingking.GetWeapon then
            return _G.Wumingking.GetWeapon(baseWid) or 0
        end
        return 0
    end

    local function SaveSkin(baseWid, skinId)
        if _G.Wumingking and _G.Wumingking.SetWeapon then
            _G.Wumingking.SetWeapon(baseWid, skinId)
        end
    end

    LAM.EquipWeapon = function(self, arg1, arg2, arg3, ...)
    _G.__lastEquipTime = os.clock()  -- ★ 记录切枪时间戳，防止 TryFix 撞车
    if type(arg1) == "table" then
        local wid = tonumber(arg1.weaponId) or 0
            local sid = tonumber(arg1.skinId) or 0
            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid

            if base and base > 0 then
                if sid >= 1100000000 then
                    -- 用户主动选了具体皮肤 → 尊重 + 保存
                    SaveSkin(base, sid)
                    if DataMgr then DataMgr.Weapon_Skin_ResID = sid end
                else
                    -- 换枪/默认皮肤 → 套用保存的皮肤
                    local saved = GetSavedSkin(base)
                    if saved > 0 and saved ~= sid then
                        arg1.skinId = saved
                        arg1.usingDiyRecommend = false
                        if DataMgr then DataMgr.Weapon_Skin_ResID = saved end
                    end
                end
            end
        end
        return origFn(self, arg1, arg2, arg3, ...)
    end

    -- 兜底刷新：进大厅后若 DataMgr 里皮肤跟保存的不一致，主动触发 EquipWeapon（让 Hook 接管）
    local function TryFix()
    -- ★ 修复：刚切枪 2 秒内跳过，避免 TryFix 强刷覆盖用户操作导致显示延迟
    if _G.__lastEquipTime and os.clock() - _G.__lastEquipTime < 2 then
        return
    end
    if type(DataMgr) ~= "table" then return end
    local wid = tonumber(DataMgr.Weapon_ID) or 0
    if wid <= 0 then return end
        local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
        if not base or base <= 0 then return end
        local saved = GetSavedSkin(base)
        if saved <= 0 then return end

        local curSid = tonumber(DataMgr.Weapon_Skin_ResID) or 0
        if curSid == saved then return end

        local tbl = {
            usingDiyRecommend = false,
            diyPlanId = "0-0",
            weaponId = base,
            skinId = saved,
        }
        if DataMgr then DataMgr.Weapon_Skin_ResID = saved end
        pcall(function() LAM:EquipWeapon(tbl, nil, true) end)
    end

    function _G.WMV4_Refresh()
        TryFix()
    end

    if _G.Mytimer_ticker then
        local _wasInLobby = false
        _G.Mytimer_ticker.AddTimerLoop(3, function()
            local ok, inLobby = pcall(function()
                return GameStatus and GameStatus.IsInLobbyOrMainCity
                    and GameStatus.IsInLobbyOrMainCity() == true
            end)
            if not (ok and inLobby) then
                _wasInLobby = false
                return
            end
            if not _wasInLobby then
                _wasInLobby = true
            end
            pcall(TryFix)
        end, -1, 1)
    end
    print("[WMV8] 已加载：Hook 版，换枪应用保存皮肤，选皮肤时尊重用户")
end)


-- ==================== 大厅仓库勾选同步（读取配置 + 自动勾选 + 保存） ====================
pcall(function()
    local WK = _G.Wumingking
    if not WK then
        print("[WardrobeSync] Wumingking 未加载，跳过")
        return
    end

    -- 关注的槽位：槽位ID -> 名称
    local SLOT_NAMES = {
        [5]  = "套装/衣服",
        [3]  = "头饰",
        [12] = "眼罩",
        [4]  = "口罩",
        [6]  = "裤子",
        [7]  = "鞋子",
        [8]  = "背包",
        [9]  = "头盔",
        [16] = "手套",
    }

    -- ==================== 工具函数 ====================
    local function getResIdFromInsId(insId)
        insId = tonumber(insId)
        if not insId then return nil end

        local LSI = _G.LobbySkinInjector
        if LSI and insId >= LSI.BASE_ID then
            local realId = insId - LSI.BASE_ID
            -- ★★★ 修复：只要在合理范围就认（原来只认 customSet，导致背包/头盔的勾选请求被丢弃）
            if realId > 0 and realId < 1000000000 then
                return realId
            end
        end

        -- 真实物品：从衣柜数据里取
        local resId = nil
        pcall(function()
            local WardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
            if WardrobeData and WardrobeData.GetHallDepotItemDataByInsID then
                local data = WardrobeData:GetHallDepotItemDataByInsID(tostring(insId))
                if data then
                    resId = data.resID or data.res_id or data.item_res_id
                end
            end
        end)
        return resId
    end

    local function getItemSubType(resId)
        if not resId then return nil end
        local cfg = nil
        pcall(function()
            if CDataTable and CDataTable.GetTableData then
                cfg = CDataTable.GetTableData("Item", resId)
            end
        end)
        return cfg and cfg.ItemSubType or nil
    end
    
    local function getItemSlotId(resId)
    if not resId then return nil end
    local cfg = nil
    pcall(function()
        if CDataTable and CDataTable.GetTableData then
            cfg = CDataTable.GetTableData("Item", resId)
        end
    end)
    if not cfg then return nil end

    -- ① 有直接字段就用（部分版本有）
    local slot = cfg.SlotID or cfg.EquipSlot or cfg.SlotId or cfg.Slot or cfg.EquipSlotID
    if slot and tonumber(slot) and tonumber(slot) > 0 then
        return tonumber(slot)
    end

    -- ② 本版本没有 SlotID，靠 WardrobeTab 推导
    -- 映射根据你 13:07 的日志实测：
    --   1411193 WardrobeTab=1  → 上衣
    --   1400165 WardrobeTab=2  → 裤子
    --   1404049 WardrobeTab=3  → 连帽衫/上衣（BAPE）
    --   1404050 WardrobeTab=4  → 裤子（BAPE）
    --   1404051 WardrobeTab=5  → 鞋子（BAPE）
    --   1407895 WardrobeTab=10 → 套装（血鸦）
    --   1410646 WardrobeTab=14 → 面饰/口罩
    local wtab = tonumber(cfg.WardrobeTab) or 0
    local WMAP = {
        [1]  = 5,
        [2]  = 6,
        [3]  = 5,
        [4]  = 6,
        [5]  = 7,
        [10] = 5,
        [14] = 4,
    }
    if WMAP[wtab] then return WMAP[wtab] end

    return nil
end

    -- ==================== 1. 读取配置并自动勾选仓库 ====================
    local function ApplySavedToWardrobe()
        if not _G.LobbySkinInjector then return false end
        
        -- 只允许勾选一次，防止多次触发导致卡顿
        if _G.__WM_WardrobeApplyingOnce then return false end
        _G.__WM_WardrobeApplyingOnce = true
        
        local LSI = _G.LobbySkinInjector

        local WardRobeHandler = nil
        pcall(function()
            WardRobeHandler = require("client.network.Protocol.WardRobeHandler")
        end)
        if not WardRobeHandler or not WardRobeHandler.send_depot_put_on_req then
            return false
        end

        -- 重新读取配置文件
        WK.Load()

        local applied = false
        _G.__WM_AUTO_WEARING = true

        local shirtId = WK.GetShirt and WK.GetShirt() or 0
local suitId = WK.GetSuit and WK.GetSuit() or 0
local pantId  = WK.GetSlot and WK.GetSlot(6) or 0
local shoeId  = WK.GetSlot and WK.GetSlot(7) or 0

-- ★★★ 主动清理冲突项：不靠游戏排斥，脚本直接发卸下请求 ★★★
local function PurgeConflicts(activeSuit, activeShirt, activePant, activeShoe)
    local rolewear = DataMgr and DataMgr.rolewear
    if type(rolewear) ~= "table" then return 0 end

    local toRemove = {}
    for _, insId in ipairs(rolewear) do
        local insNum = tonumber(insId)
        if insNum and insNum > 0 then
            local resId = getResIdFromInsId(insNum)
            if resId then
                local isSuit = _G.isSuitItem and _G.isSuitItem(resId) or false
                local slotId = getItemSlotId(resId)
                local remove = false

                -- 穿套装 → 卸裤子/鞋子
                if activeSuit > 0 and (slotId == 6 or slotId == 7) then
                    remove = true
                end
                -- 穿衣服/裤子/鞋子 → 卸套装
                if (activeShirt > 0 or activePant > 0 or activeShoe > 0) and isSuit then
                    remove = true
                end

                if remove then toRemove[#toRemove + 1] = insNum end
            end
        end
    end

    if #toRemove == 0 then return 0 end

    local WRH = nil
    pcall(function()
        WRH = require("client.network.Protocol.WardRobeHandler")
    end)
    if not WRH or not WRH.send_depot_put_down_req then return 0 end

    for _, insId in ipairs(toRemove) do
        pcall(WRH.send_depot_put_down_req, tostring(insId))
    end
    print("[WardrobeSync] 主动卸下冲突项: " .. tostring(#toRemove) .. " 个")
    return #toRemove
end

-- 先根据配置判断清哪一边（在正式穿戴前先卸冲突）
if suitId > 0 then
    pcall(PurgeConflicts, suitId, 0, 0, 0)
elseif (shirtId > 0) or (pantId > 0) or (shoeId > 0) then
    pcall(PurgeConflicts, 0, shirtId, pantId, shoeId)
end

        for slot, name in pairs(SLOT_NAMES) do
            if slot == 5 then
                -- ★ 套装有配置，直接穿上套装。绝不主动去卸下谁，交给游戏原生排斥
                if suitId > 0 then
                    if _G.AddCustomSkinItem then pcall(_G.AddCustomSkinItem, suitId) end
                    local insSuit = LSI.BASE_ID + suitId
                    pcall(WardRobeHandler.send_depot_put_on_req, tostring(insSuit))
                    applied = true
                    print("[WardrobeSync] 自动勾选: 套装 = " .. tostring(suitId))
                -- ★ 衣服有配置，穿上衣服
                elseif shirtId > 0 then
                    if _G.AddCustomSkinItem then pcall(_G.AddCustomSkinItem, shirtId) end
                    local insShirt = LSI.BASE_ID + shirtId
                    pcall(WardRobeHandler.send_depot_put_on_req, tostring(insShirt))
                    applied = true
                    print("[WardrobeSync] 自动勾选: 衣服 = " .. tostring(shirtId))
                end
            elseif slot == 6 or slot == 7 then
                -- ★ 如果是穿套装，跳过裤子(6)/鞋子(7)的自动穿戴
                if suitId <= 0 then
                    local itemId = WK.GetSlot(slot)
                    if itemId and itemId > 0 then
                        if _G.AddCustomSkinItem then
                            pcall(_G.AddCustomSkinItem, itemId)
                        end
                        local insId = LSI.BASE_ID + itemId
                        pcall(WardRobeHandler.send_depot_put_on_req, tostring(insId))
                        applied = true
                    end
                end
            else
                -- ★★★ 其他槽位：头饰3、口罩4、眼罩12、背包8、头盔9、手套16
                local itemId = WK.GetSlot(slot)
                if itemId and itemId > 0 then
                    if _G.AddCustomSkinItem then
                        pcall(_G.AddCustomSkinItem, itemId)
                    end
                    local insId = LSI.BASE_ID + itemId
                    pcall(WardRobeHandler.send_depot_put_on_req, tostring(insId))
                    applied = true
                    print("[WardrobeSync] 自动勾选: " .. tostring(name) .. " = " .. tostring(itemId))

            -- ★★★ 背包(8) / 头盔(9) / 口罩(4) / 眼罩(12) 额外注入 rolewear，让仓库 UI 显示已勾选
            if slot == 4 or slot == 8 or slot == 9 or slot == 12 then
                pcall(function()
                    if DataMgr and type(DataMgr.rolewear) == "table" then
                        local insStr = tostring(insId)
                        local found = false
                        for _, v in ipairs(DataMgr.rolewear) do
                            if tostring(v) == insStr then found = true; break end
                        end
                        if not found then
                            table.insert(DataMgr.rolewear, insStr)
                            print("[WardrobeSync] 注入 rolewear: slot=" .. tostring(slot) .. " ins=" .. insStr)
                        end
                    end
                end)
                pcall(function()
                    if EventSystem and EVENTTYPE_DATA_MGR and EVENTID_DATAMGR_ROLEWEAR_CHANGE then
                        EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLEWEAR_CHANGE)
                    end
                end)
            end
        end
    end
end
_G.__WM_AUTO_WEARING = false

    -- ★ 兜底：等穿戴请求异步完成后再做一次冲突清理（防止首轮 rolewear 未刷新）
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(1.0, function()
            _G.__WM_AUTO_WEARING = true
            if suitId > 0 then
                pcall(PurgeConflicts, suitId, 0, 0, 0)
            elseif (shirtId > 0) or (pantId > 0) or (shoeId > 0) then
                pcall(PurgeConflicts, 0, shirtId, pantId, shoeId)
            end
            _G.__WM_AUTO_WEARING = false
            if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
        end)
    end

    return applied
end

    -- ==================== 2. Hook 穿戴/卸下，保存到配置文件 ====================
    local function InstallSaveHook()
        local WardRobeHandler = nil
        pcall(function()
            WardRobeHandler = require("client.network.Protocol.WardRobeHandler")
        end)
        if not WardRobeHandler then return false end

        -- 包装穿戴请求
if not WardRobeHandler._wm_save_hooked_on then
    WardRobeHandler._wm_save_hooked_on = true
    local origOn = WardRobeHandler.send_depot_put_on_req
    if type(origOn) == "function" then
        WardRobeHandler.send_depot_put_on_req = function(insId)
            local resId = getResIdFromInsId(insId)
            local slotId = resId and getItemSlotId(resId) or nil
            local isSuit = resId and _G.isSuitItem and _G.isSuitItem(resId)

            -- ★★★ 新增：穿 slot 5 前，记录角色是否穿着裤子/鞋子
            local prePantsOn, preShoesOn = false, false
            if slotId == 5 then
                pcall(function()
                    local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
                    if not LAM then return end
                    for _, v in pairs(LAM.playerList or {}) do
                        if type(v) == "userdata" and slua.isValid(v) then
                            local comp = v.AvatarComponent2
                            if comp and slua.isValid(comp) then
                                local nad = comp.NetAvatarData
                                if nad and slua.isValid(nad) then
                                    local ad = nad.SlotSyncData
                                    if ad then
                                        for i = 0, ad:Num() - 1 do
                                            local e = ad:Get(i)
                                            if e and e.SlotID == 6 and e.ItemId and e.ItemId > 0 then prePantsOn = true end
                                            if e and e.SlotID == 7 and e.ItemId and e.ItemId > 0 then preShoesOn = true end
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                end)
            end

            -- ★ 核心：让游戏自己处理互斥排斥（穿上衣服，游戏底层自动脱掉裤子鞋子），脚本绝不干涉
            local ret = origOn(insId)
            
            -- ★ 脚本只负责默默把结果记录下来
            if _G.__WM_AUTO_WEARING then return ret end
            
            if resId then
    if slotId == 5 or isSuit then
        -- ★★★ 新增：散件判定时，延迟验证游戏原生是否脱了裤子/鞋子
        if slotId == 5 and not isSuit and (prePantsOn or preShoesOn) and _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(0.8, function()
                pcall(function()
                    local nowPantsOn, nowShoesOn = false, false
                    local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
                    if not LAM then return end
                    for _, v in pairs(LAM.playerList or {}) do
                        if type(v) == "userdata" and slua.isValid(v) then
                            local comp = v.AvatarComponent2
                            if comp and slua.isValid(comp) then
                                local nad = comp.NetAvatarData
                                if nad and slua.isValid(nad) then
                                    local ad = nad.SlotSyncData
                                    if ad then
                                        for i = 0, ad:Num() - 1 do
                                            local e = ad:Get(i)
                                            if e and e.SlotID == 6 and e.ItemId and e.ItemId > 0 then nowPantsOn = true end
                                            if e and e.SlotID == 7 and e.ItemId and e.ItemId > 0 then nowShoesOn = true end
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                    -- 之前有，现在没了 → 游戏自动脱了 → 是套装
                    if (prePantsOn and not nowPantsOn) or (preShoesOn and not nowShoesOn) then
                        if _G.Wumingking and _G.Wumingking.SetSuitDirect then
                            _G.Wumingking.SetSuitDirect(resId)
                            print("[WardrobeSync] 原生排斥验证：识别为套装 id=" .. tostring(resId))
                        end
                    end
                end)
            end)
        end

if WK.SetSlotSilent then
    WK.SetSlotSilent(5, resId, isSuit)   -- ★ 传外部已判定好的 isSuit，避免二次判定失败
    if isSuit then
        WK.SetSlotSilent(6, 0)
        WK.SetSlotSilent(7, 0)
    end
else
    WK.SetSlot(5, resId)
end
                    -- ★ 主动发卸下请求，让 UI 真的取消勾选（穿套装清5/6/7，穿衣服清套装）
                    pcall(function()
                        local LSI = _G.LobbySkinInjector
                        if not LSI or type(DataMgr.rolewear) ~= "table" then return end
                        if not WardRobeHandler.send_depot_put_down_req then return end
                        local justOn = tonumber(insId) or -1
                        for i = 1, #DataMgr.rolewear do
                            local insNum = tonumber(DataMgr.rolewear[i])
                            if insNum and insNum > 0 and insNum ~= justOn and insNum >= LSI.BASE_ID then
                                local realId = insNum - LSI.BASE_ID
                                local cfg = CDataTable.GetTableData("Item", realId)
                                if cfg then
                                    local rSlot = cfg.SlotID
                                    local rIsSuit = _G.isSuitItem and _G.isSuitItem(realId) or false
                                    local remove = false
                                    if isSuit then
                                        if rSlot == 5 or rSlot == 6 or rSlot == 7 then remove = true end
                                    else
                                        if rIsSuit then remove = true end
                                    end
                                    if remove then
                                        pcall(WardRobeHandler.send_depot_put_down_req, tostring(insNum))
                                    end
                                end
                            end
                        end
                    end)
                    if _G._wkSaveDebounceTimer then
                        pcall(function() _G.Mytimer_ticker.RemoveTimer(_G._wkSaveDebounceTimer) end)
                    end
                    _G._wkSaveDebounceTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
                        if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
                    end)
                    return ret
                end

            -- ★★★ 修复：删除 getItemSubType 兜底 ★★★
            -- ItemSubType 是游戏内部物品分类（口罩可能是 6、上衣是 1 等小数字），
            -- 和装备槽位 SLOT_NAMES 的 key（5/3/12/4/6/7/8/9/16）完全不是一个系统！
            -- 口罩一旦 ItemSubType == 6，就会被误判成"裤子"写到 D.G[6]，
            -- 下次进游戏 PANT=口罩ID，穿裤子就戴了口罩。
            -- 现在只用 SlotID 精确匹配，识别不到的物品走下面的 SlotSyncData 延迟兜底（更准）。
            local finalSlot = slotId
if finalSlot and SLOT_NAMES[finalSlot] then
    WK.SetSlot(finalSlot, resId)
    -- 穿裤子(6)/鞋子(7) → 只清套装配置，绝不动 SHIRT
    if finalSlot == 6 or finalSlot == 7 then
        -- ✅ 新：只清 SUIT，SHIRT/PANT/SHOE 全保留
        if WK.ClearSuitOnly then WK.ClearSuitOnly() end
        -- ★ 主动发卸下请求，让 UI 取消套装勾选
        pcall(function()
            local LSI = _G.LobbySkinInjector
            if not LSI or type(DataMgr.rolewear) ~= "table" then return end
            if not WardRobeHandler.send_depot_put_down_req then return end
            local justOn = tonumber(insId) or -1
            for i = 1, #DataMgr.rolewear do
                local insNum = tonumber(DataMgr.rolewear[i])
                if insNum and insNum > 0 and insNum ~= justOn and insNum >= LSI.BASE_ID then
                    local realId = insNum - LSI.BASE_ID
                    if _G.isSuitItem and _G.isSuitItem(realId) then
                        pcall(WardRobeHandler.send_depot_put_down_req, tostring(insNum))
                    end
                end
            end
        end)
    end
    if _G._wkSaveDebounceTimer then
        pcall(function() _G.Mytimer_ticker.RemoveTimer(_G._wkSaveDebounceTimer) end)
    end
    _G._wkSaveDebounceTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
        if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
    end)
    print("[WardrobeSync] 勾选保存: " .. tostring(SLOT_NAMES[finalSlot]) .. " = " .. tostring(resId))
else
    -- ★★★ 兜底：槽位识别失败 → 延迟对比 SlotSyncData 找真实槽位 ★★★
    -- 用于口罩/面饰/眼罩等没有 SlotID 字段也匹配不到 WardrobeTab 的物品
    if resId and _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(0.8, function()
            pcall(function()
                local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
                if not LAM then return end
                for _, v in pairs(LAM.playerList or {}) do
                    if type(v) == "userdata" and slua.isValid(v) then
                        local comp = v.AvatarComponent2
                        local ad = comp and comp.NetAvatarData and comp.NetAvatarData.SlotSyncData
                        if ad then
                            -- 遍历所有槽位，找 ItemId == resId 的那个槽位
                            for i = 0, ad:Num() - 1 do
                                local e = ad:Get(i)
                                if e and e.ItemId == resId and e.SlotID then
                                    local realSlot = e.SlotID
                                    if SLOT_NAMES[realSlot] then
                                        local curVal = WK.GetSlot(realSlot) or 0
                                        if curVal ~= resId then
                                            WK.SetSlot(realSlot, resId)
                                            print("[WardrobeSync] ★ SlotSyncData兜底保存: " .. tostring(SLOT_NAMES[realSlot]) .. " = " .. tostring(resId))
                                        end
                                    end
                                end
                            end
                        end
                        break
                    end
                end
            end)
        end)
    end
end
            end
            return ret
        end
    end
end

        -- 包装卸下请求
if not WardRobeHandler._wm_save_hooked_down then
    WardRobeHandler._wm_save_hooked_down = true
    local origDown = WardRobeHandler.send_depot_put_down_req
    if type(origDown) == "function" then
        WardRobeHandler.send_depot_put_down_req = function(insId)
            local resId = getResIdFromInsId(insId)
            local isSlot5 = false
            
            if resId then
                isSlot5 = (getItemSlotId(resId) == 5) or (_G.isSuitItem and _G.isSuitItem(resId))
            end

            local LSI = _G.LobbySkinInjector
            if not isSlot5 and LSI and tonumber(insId) and tonumber(insId) >= LSI.BASE_ID then
                local realId = tonumber(insId) - LSI.BASE_ID
                if (getItemSlotId(realId) == 5) or (_G.isSuitItem and _G.isSuitItem(realId)) then
                    isSlot5 = true
                    resId = realId
                end
            end

            local ret = origDown(insId)

            if _G.__WM_AUTO_WEARING then return ret end
            if not resId then return ret end

            -- ★ 只有"当前配置就是这个 ID"才清，避免主动清理冲突项时误清刚穿的套装
            local isSuit = _G.isSuitItem and _G.isSuitItem(resId) or false
            if isSlot5 then
                local curSuit = (WK.GetSuit and WK.GetSuit()) or 0
                local curShirt = (WK.GetShirt and WK.GetShirt()) or 0
                if (isSuit and curSuit == resId) or ((not isSuit) and curShirt == resId) then
                    WK.SetSlot(5, 0)
                    if _G._wkSaveDebounceTimer then
                        pcall(function() _G.Mytimer_ticker.RemoveTimer(_G._wkSaveDebounceTimer) end)
                    end
                    _G._wkSaveDebounceTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
                        if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
                    end)
                    print("[WardrobeSync] 卸下衣服/套装: " .. tostring(resId))
                end
                return ret
            end

            -- ★ 卸下背包/头盔/头饰/口罩/眼罩/手套：优先 SlotID，退回 ItemSubType
            local checkSlot = getItemSlotId(resId)
            if not checkSlot or not SLOT_NAMES[checkSlot] then
                checkSlot = getItemSubType(resId)
            end
            if checkSlot and SLOT_NAMES[checkSlot] then
                local curVal = WK.GetSlot(checkSlot) or 0
                if curVal == resId then
                    WK.SetSlot(checkSlot, 0)
                    print("[WardrobeSync] 卸下: " .. tostring(SLOT_NAMES[checkSlot]) .. " = 0")
                end
            end
            return ret
        end
    end
end
    return true
end

-- ==========================================================
-- ★★★ 套装互斥持续守护（100% 生效的核心）★★★
-- 只要 D.S > 0（穿套装），每 0.5 秒强制清角色身上 slot 6/7
-- 不依赖游戏原生排斥、不依赖 DataMgr.rolewear 反查
-- ==========================================================
if _G.Mytimer_ticker and not _G.__WM_SuitGuardInstalled then
    _G.__WM_SuitGuardInstalled = true
    local _suitGuardTick = 0
    _G.Mytimer_ticker.AddTimerLoop(0.5, function()
        pcall(function()
            -- ① 条件判断：只在大厅 + 有套装时才跑
            if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then return end
            -- ★ 只有套装模式（SUIT>0）才需要守护
            local needClear = (WK.GetSuit and WK.GetSuit() > 0)
            if not needClear then return end
            if not (WK.HasAnyConfig and WK.HasAnyConfig()) then return end

            -- ② 拿大厅角色
            local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
            if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return end
            local ch = nil
            for _, v in pairs(LAM.playerList) do
                if type(v) == "userdata" and slua.isValid(v) then ch = v; break end
            end
            if not ch then return end

            local comp = ch.AvatarComponent2
            if not comp or not slua.isValid(comp) then return end
            local nad = comp.NetAvatarData
            if not nad or not slua.isValid(nad) then return end
            local ad = nad.SlotSyncData
            if not ad then return end

            -- ③ 清 slot 6/7 角色数据
            local dirty = false
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e and (e.SlotID == 6 or e.SlotID == 7) and e.ItemId ~= 0 then
                    e.ItemId = 0
                    ad:Set(i, e)
                    dirty = true
                end
            end

            if dirty then
                pcall(function() comp:OnRep_BodySlotStateChanged() end)
                _suitGuardTick = _suitGuardTick + 1
                -- 只在真正清过的时候打印一次（避免每 0.5 秒刷屏）
                if _suitGuardTick % 10 == 1 then
                    print("[SuitGuard] 已强制清角色 slot 6/7（穿套装中）")
                end
            end

            -- ④ 每 2 秒扫一次 rolewear，主动发卸下请求（清仓库 UI 勾选）
            if _suitGuardTick % 4 == 0 then
                pcall(function()
                    local WRH = require("client.network.Protocol.WardRobeHandler")
                    local rolewear = DataMgr and DataMgr.rolewear
                    if type(rolewear) ~= "table" then return end
                    if not WRH or not WRH.send_depot_put_down_req then return end
                    local LSI = _G.LobbySkinInjector
                    for _, insId in ipairs(rolewear) do
                        local insNum = tonumber(insId)
                        if insNum and insNum > 0 then
                            local realId = nil
                            if LSI and insNum >= LSI.BASE_ID then
                                realId = insNum - LSI.BASE_ID
                            end
                            if realId then
                                local cfg = CDataTable.GetTableData("Item", realId)
                                if cfg and (cfg.SlotID == 6 or cfg.SlotID == 7) then
                                    pcall(WRH.send_depot_put_down_req, tostring(insNum))
                                    print("[SuitGuard] 主动卸下 rolewear 里的 slot 6/7: " .. tostring(realId))
                                end
                            end
                        end
                    end
                end)
            end
            _suitGuardTick = _suitGuardTick + 1
        end)
    end, -1, 1)
    print("[SuitGuard] 套装互斥持续守护已启动（每 0.5 秒扫描）")
end

-- ==================== 3. 启动流程 ====================
local function TryStart()
    if not _G.LobbySkinInjector then return false end
    local ok = InstallSaveHook()
    if not ok then return false end
    ApplySavedToWardrobe()
    return true
end

    if not TryStart() then
        local tries = 0
        local function Retry()
            tries = tries + 1
            if TryStart() then return end
            if tries < 3 then
                local ok, tt = pcall(require, "common.time_ticker")
                if ok and tt and tt.AddTimer then
                    tt.AddTimer(1, Retry)
                end
            end
        end
        Retry()
    end

    if _G.Mytimer_ticker then
        local wasInLobby = false
        _G.Mytimer_ticker.AddTimerLoop(2, function()
            local inLobby = false
            pcall(function()
                inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity
                    and GameStatus.IsInLobbyOrMainCity() == true
            end)
            if inLobby and not wasInLobby then
                wasInLobby = true
                if not _G.__WM_WardrobeApplyingOnce then
                    pcall(ApplySavedToWardrobe)
                end
            elseif not inLobby then
                wasInLobby = false
                _G.__WM_WardrobeApplyingOnce = nil
            end
        end, -1, 1)
    end
end)




-- ==================== 套装（连体衣）独立保存支持 ====================
-- 因为套装和衣服共用 SlotID 5，但游戏里是独立分类
-- 通过 ItemSubType 判断类型：
--   套装 → 保存到 SUIT= 行
--   衣服 → 保存到 SHIRT= 行
-- 二者互斥，同时只有一个有效
--
-- 【重要】SUIT_ITEM_SUBTYPES 里的值是"套装的 ItemSubType"
-- 常见版本可能是 13，如果实测套装仍被算成衣服，请调整这个值
-- ★ 常见套装 ItemSubType（不同版本/不同皮肤可能变化，尽量多列几个）
-- 如果实测套装仍被当成衣服，可以打印一下 ItemSubType 加到列表里
_G.SUIT_ITEM_SUBTYPES = {}

_G.SuitSaver = _G.SuitSaver or {}
do
    local SS = _G.SuitSaver

    -- 判断是否套装（连体衣）—— 唯一保留的函数
function _G.isSuitItem(resId)
    if not resId or resId <= 0 then return false end
    local cfg = nil
    pcall(function()
        if CDataTable and CDataTable.GetTableData then
            cfg = CDataTable.GetTableData("Item", resId)
        end
    end)
    if not cfg then return false end
    -- ★ 游戏衣柜分类：Tab=10 是套装，Tab=3 是单件上衣
    local tab = tonumber(cfg.WardrobeTab) or 0
    if tab == 10 then return true end
    return false
end

    -- 兼容旧接口：读/写 SUIT= 直接走 Wumingking 的 D.S
    function SS.Read()
        if _G.Wumingking and _G.Wumingking.GetSuit then
            return _G.Wumingking.GetSuit()
        end
        return 0
    end
    function SS.Write(itemId)
        itemId = math.floor(tonumber(itemId) or 0)
        if _G.Wumingking and _G.Wumingking.SetSlot then
            _G.Wumingking.SetSlot(5, itemId)
        end
        return true
    end

    print("[SuitSaver] 已集成到 Wumingking.D.S，SUIT_ITEM_SUBTYPES=" ..
        table.concat(_G.SUIT_ITEM_SUBTYPES, ","))
end

pcall(function()
    local IDS = {1407550, 1400129, 404000, 405000}

    -- 清 LobbySkinInjector 缓存
    if _G.LobbySkinInjector then
        local LSI = _G.LobbySkinInjector
        for _, id in ipairs(IDS) do
            if LSI.customWorn then LSI.customWorn[id] = nil end
            if LSI.fakeByRes then LSI.fakeByRes[id] = nil end
            if LSI.customSet then LSI.customSet[id] = nil end
        end
    end

    -- 清 DataMgr.rolewear 里的假实例
    if DataMgr and type(DataMgr.rolewear) == "table" then
        for i = #DataMgr.rolewear, 1, -1 do
            local v = tonumber(DataMgr.rolewear[i])
            if v and v >= 900000000 then
                local realId = v - 900000000
                for _, id in ipairs(IDS) do
                    if realId == id then
                        table.remove(DataMgr.rolewear, i)
                        break
                    end
                end
            end
        end
    end
end)


-- ==================== 手套极速响应系统（拿枪隐藏 / 收枪显示） ====================
if _G.Mytimer_ticker then
    local _lastGunState = nil
    local _originalGloves = nil   -- 拿枪前记录的原始手套ID

    _G.Mytimer_ticker.AddTimerLoop(0.5, function()
        local enabled = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("GLOVES_HIDE_ON_GUN", 0) == 1)
        -- ★性能：开关未开且之前也没隐藏过手套，直接跳过，不做角色链路取值
        if not enabled and _lastGunState == nil and _originalGloves == nil then return end

        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return end
        local ch = pc:GetPlayerCharacterSafety()
        if not ch or not slua.isValid(ch) then return end

        local comp = ch.AvatarComponent2
        if not comp or not slua.isValid(comp) then return end
        local nad = comp.NetAvatarData
        if not nad or not slua.isValid(nad) then return end
        local ad = nad.SlotSyncData
        if not ad then return end

        -- 开关关闭时：如果之前隐藏过手套，恢复
        if not enabled then
            if _lastGunState ~= nil then
                _lastGunState = nil
                if _originalGloves ~= nil then
                    for i = 0, ad:Num() - 1 do
                        local e = ad:Get(i)
                        if e and e.SlotID == 16 then
                            if e.ItemId ~= _originalGloves then
                                e.ItemId = _originalGloves
                                ad:Set(i, e)
                                pcall(function() comp:OnRep_BodySlotStateChanged() end)
                            end
                            break
                        end
                    end
                    _originalGloves = nil
                end
            end
            return
        end

        local weapon = ch:GetCurrentWeapon()
        local wid = 0
        if weapon and slua.isValid(weapon) then
            local did = weapon:GetItemDefineID()
            if did and did.TypeSpecificID then
                wid = did.TypeSpecificID
            end
        end

        local baseWid = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
        -- 枪械 ID 段：101000~107999（排除近战 108xxx、手雷、空手）
        local isGun = (baseWid and baseWid >= 101000 and baseWid < 108000)

        if _lastGunState == isGun then return end
        _lastGunState = isGun

        local targetGloves
        if isGun then
            -- 记录原始手套（用于收枪恢复）
            if _originalGloves == nil then
                for i = 0, ad:Num() - 1 do
                    local e = ad:Get(i)
                    if e and e.SlotID == 16 then
                        _originalGloves = e.ItemId or 0
                        break
                    end
                end
            end
            targetGloves = 450001   -- 隐藏手套
        else
            if _originalGloves ~= nil then
                targetGloves = _originalGloves
                _originalGloves = nil
            else
                targetGloves = _G.GlovesSkin or 0
            end
        end

        local found = false
        for i = 0, ad:Num() - 1 do
            local e = ad:Get(i)
            if e and e.SlotID == 16 then
                found = true
                if e.ItemId ~= targetGloves then
                    e.ItemId = targetGloves
                    ad:Set(i, e)
                    pcall(function() comp:OnRep_BodySlotStateChanged() end)
                end
                break
            end
        end

        if not found and targetGloves > 0 then
            ad:Add({ SlotID = 16, ItemId = targetGloves })
            pcall(function() comp:OnRep_BodySlotStateChanged() end)
        end
    end, -1, 0.15)   -- ★ 间隔 0.15 秒
end


-- ==================== 局内只刷 0x24 和 0x28 ====================
if _G.Mytimer_ticker then
    _G.Mytimer_ticker.AddTimerLoop(1.0, function()
        -- 仅限局内生效
        local inGame = false
        pcall(function() inGame = GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true end)
        
        if inGame then
            -- 读取你设置菜单里的数值
            local color = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("TEAM_UNIFORM_COLOR", 0)) or 0
            local pattern = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("TEAM_UNIFORM_PATTERN", 0)) or 0
            
            -- 只要你有选数值，并且环境里有 xsnb_tbys，就直接调用
            if (color > 0 or pattern > 0) and _G.xsnb_tbys then
                
                -- ★ 核心：只写 0x24 (颜色)
                if color > 0 then 
                    pcall(_G.xsnb_tbys, 5, color, nil, 0x24) 
                end
                
                -- ★ 核心：只写 0x28 (图标)
                if pattern > 0 then 
                    pcall(_G.xsnb_tbys, 5, pattern, nil, 0x28) 
                end
                
            end
        end
    end, -1, 1)
end


-- ==================== 大厅武器皮肤最终刷新 V36（背包/头盔/护甲全防覆盖版） ====================
if not _G.__LobbyWeaponV14 then
    _G.__LobbyWeaponV14 = true

    local function safeRequire(paths)
        for _, path in ipairs(paths) do
            local ok, mod = pcall(require, path)
            if ok and mod then return mod end
        end
        return nil
    end

    -- 1. 仓库勾选伪造
    local function InjectArmorySystem()
        local ArmorySystem = safeRequire({ "client.logic.armory.logic_armory", "Client.logic.armory.logic_armory" })
        if not ArmorySystem then return end
        if not ArmorySystem.rsp_list then ArmorySystem.rsp_list = {} end
        if not ArmorySystem.rsp_list.install_list then ArmorySystem.rsp_list.install_list = {} end

        if _G.Wumingking and _G.WeaponNameToID then
            for weaponName, baseId in pairs(_G.WeaponNameToID) do
                local targetSkin = _G.Wumingking.GetWeapon(baseId)
                if targetSkin and targetSkin > 0 then
                    local fakeInst = 900000000 + targetSkin
                    local cur = ArmorySystem.rsp_list.install_list[baseId]
                    local curSkin = cur and cur.skin_id
                    if curSkin ~= targetSkin then
                        if ArmorySystem.install_weapon_skin_rsp then
                            pcall(function()
                                ArmorySystem.install_weapon_skin_rsp({}, 0, baseId, fakeInst)
                            end)
                        end
                    end
                end
            end
        end
    end

    -- 2. Hook 协议层
    local ArmoryHandler = safeRequire({ "client.network.Protocol.ArmoryHandler", "Client.network.Protocol.ArmoryHandler" })
    if ArmoryHandler then
        local ArmorySystem = safeRequire({ "client.logic.armory.logic_armory", "Client.logic.armory.logic_armory" })
        if ArmorySystem then
            if ArmoryHandler.send_install_weapon_skin and not ArmoryHandler._fake_hooked_install then
                ArmoryHandler._fake_hooked_install = true
                local original = ArmoryHandler.send_install_weapon_skin
                ArmoryHandler.send_install_weapon_skin = function(client_data, weapon_id, instanceID)
                    if tonumber(instanceID) >= 900000000 or instanceID == 0 then
                        ArmorySystem.install_weapon_skin_rsp(client_data, 0, weapon_id, tonumber(instanceID))
                        return
                    end
                    return original(client_data, weapon_id, instanceID)
                end
            end
            if ArmoryHandler.send_uninstall_weapon_skin and not ArmoryHandler._fake_hooked_uninstall then
                ArmoryHandler._fake_hooked_uninstall = true
                local original = ArmoryHandler.send_uninstall_weapon_skin
                ArmoryHandler.send_uninstall_weapon_skin = function(client_data, weapon_id)
                    local cur = ArmorySystem.rsp_list and ArmorySystem.rsp_list.install_list and ArmorySystem.rsp_list.install_list[weapon_id]
                    local skinId = cur and cur.instance_id
                    if skinId and tonumber(skinId) >= 900000000 then
                        ArmorySystem.uninstall_weapon_skin_rsp(client_data, 0, weapon_id)
                        return
                    end
                    return original(client_data, weapon_id)
                end
            end
        end
    end

    -- ★★★ 3. 终极防错位：把背包、头盔、护甲的修复全部补齐！ ★★★
    local function FixHairAndBodyNoRebuild(LAM)
    pcall(function()
        local targetActor = nil
        -- ★ 只修本地玩家，防止把背包/头盔/护甲/口罩写到队友身上
        local selfUid = nil
        pcall(function()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                selfUid = tostring(DataMgr.roleData.uid)
            end
        end)
        if selfUid then
            for uid, v in pairs(LAM.playerList or {}) do
                if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                    targetActor = v
                    break
                end
            end
        end
        if not slua.isValid(targetActor) then
            local first, count = nil, 0
            for _, v in pairs(LAM.playerList or {}) do
                if type(v) == "userdata" and slua.isValid(v) then
                    count = count + 1
                    if not first then first = v end
                end
            end
            if count == 1 then targetActor = first end
        end
        if not slua.isValid(targetActor) then return end
            if not slua.isValid(targetActor) then return end
            
            local comp = targetActor.AvatarComponent2
            if not comp or not slua.isValid(comp) then return end
            local nad = comp.NetAvatarData
            if not nad or not slua.isValid(nad) then return end
            local ad = nad.SlotSyncData
            if not ad then return end

            -- 基础部位
            local fixes = {
                [2]  = _G.HairSkin,     [3]  = _G.HatSkin,      [4]  = _G.FaceSkin,
                [12] = _G.MaskSkin,     [5]  = _G.SuitSkin,     [6]  = _G.PantSkin,
                [7]  = _G.ShoeSkin,     [16] = _G.GlovesSkin,
            }

            local changed = false
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e then
                    local slot = e.SlotID
                    local targetId = fixes[slot]
                    
                    -- 基础槽位覆盖
                    if targetId and targetId > 0 then
                        if e.ItemId ~= targetId then
                            e.ItemId = targetId
                            ad:Set(i, e)
                            changed = true
                        end
                    end

                    -- ★★★ 新增：背包 (8) ★★★
                    if slot == 8 then
                        local lvl = tonumber(e.AdditionalItemID) or 1
                        local bagSkin = _G["Backpack" .. lvl .. "Skin"] or 0
                        if bagSkin > 0 and e.ItemId ~= bagSkin then
                            e.ItemId = bagSkin
                            ad:Set(i, e)
                            changed = true
                        end
                    end

                    -- ★★★ 新增：头盔 (9) ★★★
                    if slot == 9 then
                        local lvl = tonumber(e.AdditionalItemID) or 1
                        local helmetSkin = _G["Helmet" .. lvl .. "Skin"] or 0
                        if helmetSkin > 0 and e.ItemId ~= helmetSkin then
                            e.ItemId = helmetSkin
                            ad:Set(i, e)
                            changed = true
                        end
                    end

                    -- ★★★ 新增：防弹衣 (10) ★★★
                    if slot == 10 then
                        local lvl = tonumber(e.AdditionalItemID) or 1
                        local armorSkin = _G["Armor" .. lvl .. "Skin"] or 0
                        if armorSkin > 0 and e.ItemId ~= armorSkin then
                            e.ItemId = armorSkin
                            ad:Set(i, e)
                            changed = true
                        end
                    end
                end
            end

            if changed then
                pcall(function() comp:OnRep_BodySlotStateChanged() end)
            end
        end)
    end

    -- 4. 全图 3D 武器模型强刷
    local function LobbyAllWeaponsRefresh()
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return end

        pcall(function()
            local UGS = import("GameplayStatics")
            -- ★性能：不扫全场景 Actor，只扫武器类
            local clsw = nil
            for _, cn in ipairs({ "WeaponBase", "STExtraWeaponBase", "BattleWeaponBase" }) do
                local okc, c = pcall(import, cn)
                if okc and c then clsw = c; break end
            end
            if not clsw then return end
            local allActors = UGS.GetAllActorsOfClass(world, clsw, {})
            if not allActors then return end
            for i = 0, allActors:Num() - 1 do
                local a = allActors:Get(i)
                if slua.isValid(a) then
                    local arr = a.synData
                    if arr and slua.isValid(arr) then
                        local d = arr:Get(7)
                        if d and slua.isValid(d) then
                            local curId = slua.IndexReference(d, "defineID").TypeSpecificID
                            local baseWid = _G.getBaseWeaponID and _G.getBaseWeaponID(curId) or curId
                            local targetSkin = (_G.Wumingking and _G.Wumingking.GetWeapon and _G.Wumingking.GetWeapon(baseWid)) or 0
                            
                            if targetSkin > 0 and targetSkin ~= curId then
                                slua.IndexReference(d, "defineID").TypeSpecificID = targetSkin
                                arr:Set(7, d)
                                if a.ChangeItemAvatar then pcall(function() a:ChangeItemAvatar(targetSkin, true) end) end
                                if a.DelayHandleAvatarMeshChanged then pcall(function() a:DelayHandleAvatarMeshChanged() end) end
                                local wac = a.WeaponAvatarComponent
                                if wac and slua.isValid(wac) then
                                    if wac.ChangeItemAvatar then pcall(function() wac:ChangeItemAvatar(targetSkin, true) end) end
                                    if wac.OnRep_AvatarId then pcall(function() wac:OnRep_AvatarId() end) end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    _G.__LobbyRefreshRunning = false
    _G.__justExitedMatch = false

    -- ========== 5. 原版绝招连招 ==========
    _G.LobbyWeaponRefreshFinal = function(skinOverride)
    -- ★★★ 终极防御：只要不是在大厅，不准执行这个刷新隐藏逻辑 ★★★
    if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true) then
        return
    end

    if _G.__justExitedMatch then
        print("[DazhiMH] 刚退对局，强制屏蔽刷新防遁地！")
        return
    end

    if _G.__LobbyRefreshRunning then return end
    _G.__LobbyRefreshRunning = true

        InjectArmorySystem()

        if not DataMgr then _G.__LobbyRefreshRunning = false; return end
        local wid = tonumber(DataMgr.Weapon_ID) or 0
        if wid <= 0 then _G.__LobbyRefreshRunning = false; return end

        local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
        local target = skinOverride or (_G.Wumingking and _G.Wumingking.GetWeapon and _G.Wumingking.GetWeapon(base)) or 0
        if target <= 0 then _G.__LobbyRefreshRunning = false; return end

        local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
        if not ok or not LAM then _G.__LobbyRefreshRunning = false; return end

        DataMgr.Weapon_Skin_ResID = target

        local targetActor, w, wac, comp
pcall(function()
    local actor = nil
    pcall(function() actor = LAM:GetOperateAvatarByAvatarID(401985) end)
    if not slua.isValid(actor) then
        -- ★ 只取本地玩家，防止刷到队友的武器上
        local selfUid = nil
        pcall(function()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                selfUid = tostring(DataMgr.roleData.uid)
            end
        end)
        if selfUid then
            for uid, v in pairs(LAM.playerList or {}) do
                if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                    actor = v
                    break
                end
            end
        end
        if not slua.isValid(actor) then
            local first, count = nil, 0
            for _, v in pairs(LAM.playerList or {}) do
                if type(v) == "userdata" and slua.isValid(v) then
                    count = count + 1
                    if not first then first = v end
                end
            end
            if count == 1 then actor = first end
        end
    end
            if slua.isValid(actor) then
                targetActor = actor
                local wm = nil
                pcall(function() wm = actor:GetWeaponManager() end)
                if wm and slua.isValid(wm) then pcall(function() w = wm:GetCurrentWeapon() end) end
                if w and slua.isValid(w) then pcall(function() wac = w.WeaponAvatarComponent end) end
                pcall(function() comp = actor.AvatarComponent2 end)
            end
        end)

        local tbl = { usingDiyRecommend = false, diyPlanId = "0-0", weaponId = base, skinId = target }
        local emptyTbl = { usingDiyRecommend = false, diyPlanId = "0-0", weaponId = 0, skinId = 0 }

        local function doSyncData()
            if not DataMgr then return end
            DataMgr.Weapon_Skin_ResID = target
            if not slua.isValid(w) then return end
            local arr = w.synData
            if arr and slua.isValid(arr) then
                local d = arr:Get(7)
                if d and slua.isValid(d) then
                    slua.IndexReference(d, "defineID").TypeSpecificID = target
                    arr:Set(7, d)
                end
            end
        end

        pcall(function()
            doSyncData()
            if slua.isValid(w) and w.ChangeItemAvatar then w:ChangeItemAvatar(target, true) end
            if slua.isValid(w) and w.DelayHandleAvatarMeshChanged then w:DelayHandleAvatarMeshChanged() end
            if slua.isValid(wac) and wac.ChangeItemAvatar then wac:ChangeItemAvatar(target, true) end
            if slua.isValid(wac) and wac.OnRep_AvatarId then wac:OnRep_AvatarId() end
            if slua.isValid(wac) and wac.OnRep_AvatarChanged then wac:OnRep_AvatarChanged() end
            if slua.isValid(wac) and wac.OnRep_SkinChanged then wac:OnRep_SkinChanged() end
            if slua.isValid(comp) and comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged() end
            if slua.isValid(comp) and comp.InitDepotCommonPutOn then comp:InitDepotCommonPutOn() end
        end)

        pcall(function() LAM:EquipWeapon(emptyTbl, nil, true) end)
        
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(0.1, function()
                pcall(function() LAM:EquipWeapon(tbl, nil, true) end)
                
                _G.Mytimer_ticker.AddTimer(0.2, function()
                    local origLoc = nil
                    if slua.isValid(targetActor) then
                        origLoc = targetActor:K2_GetActorLocation()
                    end

if slua.isValid(targetActor) then
    pcall(function() LAM:UpdatePlayer(targetActor) end)
    pcall(function() LAM:RefreshAvatar() end)
    pcall(function() LAM:RefreshMyAvatar() end)
end

-- ★ 新增：清理大厅可能残留的克隆人模型
pcall(function()
    local validActors = {}
    if slua.isValid(targetActor) then table.insert(validActors, targetActor) end
    
    local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
    if slua.isValid(world) then
        local UGS = import("GameplayStatics")
        -- ★性能：不扫全场景 Actor，只扫角色类
        local clsc = nil
        for _, cn in ipairs({ "Character", "Avatar" }) do
            local okc, c = pcall(import, cn)
            if okc and c then clsc = c; break end
        end
        local allActors = clsc and UGS.GetAllActorsOfClass(world, clsc, {}) or nil
        if allActors then
            for i = 0, allActors:Num() - 1 do
                local a = allActors:Get(i)
                local name = a:GetClass():GetName() or ""
                -- 只针对玩家角色类进行清理，绝不碰其它场景物件
                if (name:find("Character") or name:find("Avatar")) and not name:find("Weapon") and not name:find("DeadBox") then
                    local isTracked = false
                    for _, valid in ipairs(validActors) do
                        if a == valid then isTracked = true; break end
                    end
                    if not isTracked then
                        pcall(function() a:K2_DestroyActor() end)
                    end
                end
            end
        end
    end
end)

                    _G.Mytimer_ticker.AddTimer(1.2, function()
                        FixHairAndBodyNoRebuild(LAM) -- ★ 这个函数现在会把背包、头盔、护甲全刷回去！
                        LobbyAllWeaponsRefresh()
                        _G.__LobbyRefreshRunning = false
                    end)
                end)
            end)
        end
    end

    -- ========== 触发机制 ==========
    if _G.Mytimer_ticker then
        local _wasInLobby = false
        local _wasInGame = false
        
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                local inGame = GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true
                local inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true
                
                if _wasInGame and not inGame and inLobby then
                    _G.__justExitedMatch = true
                    print("[DazhiMH] 检测到退出对局，开启防遁地锁 5 秒。")
                    _G.Mytimer_ticker.AddTimer(5.0, function()
                        _G.__justExitedMatch = false
                    end)
                end

                if inLobby and not _wasInLobby then
                    _wasInLobby = true
                    if not _G.__justExitedMatch then
                        _G.Mytimer_ticker.AddTimer(0.5, function()
                            pcall(_G.LobbyWeaponRefreshFinal)
                        end)
                    end
                elseif not inLobby then
                    _wasInLobby = false
                end
                
                _wasInGame = inGame
            end)
        end, -1, 1)
    end

    pcall(function()
        local C = _G.DazhiMH_Config
        if C and type(C.ApplyWeaponSkin) == "function" and not C.__v14Wrapped then
            C.__v14Wrapped = true
            local orig = C.ApplyWeaponSkin
            C.ApplyWeaponSkin = function(k, v)
                local r = orig(k, v)
                if _G.Mytimer_ticker then
                    _G.Mytimer_ticker.AddTimer(0.1, function() pcall(_G.LobbyWeaponRefreshFinal) end)
                end
                return r
            end
        end
    end)
end


-- ==================== ★ 近战武器便利刷肤（绝对防御版 V2 · 彻底防枪械污染）★ ====================
_G.MeleeSkinRefresher = _G.MeleeSkinRefresher or {}
do
    local M = _G.MeleeSkinRefresher
    M._installed = true

    M.Enabled  = true
    M.TICK_SEC = 2.0

    -- 近战基础ID（唯一合法的近战底座白名单）
    local MELEE_BASE = {
        [108001] = "Machete",
        [108004] = "PAN",
        [108005] = "Dagger",
    }

    -- 近战 7 位变体 → 底座（1080041 → 108004 等）
    local MELEE_ID_BASE = {
        [108001] = 108001, [1080010] = 108001, [1080011] = 108001, [1080019] = 108001,
        [108004] = 108004, [1080040] = 108004, [1080041] = 108004, [1080042] = 108004,
        [1080043] = 108004, [1080044] = 108004, [1080049] = 108004,
        [108005] = 108005, [1080050] = 108005, [1080059] = 108005,
    }

    -- 近战皮肤 ID → 底座（用于共用皮肤段时区分，如 1108001xxx）
    local MELEE_SKIN_BASE = {
        [1108005052] = 108005, -- 清夜蝶吻匕首
        [1108004027] = 108004, -- 冰雪晶核
        [1108004416] = 108004, -- 焰舞折扇平底锅
        [1108004380] = 108004, -- 红莲哥斯拉平底锅
        [1108004283] = 108004, -- 至臻壁垒平底锅
        [1108004230] = 108004, -- 莎莉-Pan
        [1108001081] = 108001, -- 红莲战斧
        [1108001099] = 108001, -- Juan Soto 棒球棍
    }

    -- ============ 皮肤段判定 ============
    local function isMeleeSkin(skinId)
        skinId = tonumber(skinId) or 0
        if skinId <= 0 then return false end
        if MELEE_BASE[skinId] then return true end
        if MELEE_ID_BASE[skinId] then return true end
        if skinId == 1081201 then return true end
        if skinId >= 1108001001 and skinId <= 1108001999 then return true end
        if skinId >= 1108004001 and skinId <= 1108004999 then return true end
        if skinId >= 1108005001 and skinId <= 1108005999 then return true end
        return false
    end

    -- ============ ID 段判定（用户输入/配置ID 的合法性） ============
    local function isMeleeWeaponId(wid)
        wid = tonumber(wid) or 0
        if wid <= 0 then return false end
        if MELEE_BASE[wid] then return true end
        if wid == 1081201 then return true end
        if wid >= 108001 and wid <= 108999 then return true end
        if wid >= 1080011 and wid <= 1089999 then return true end
        if wid >= 1108001001 and wid <= 1108005999 then return true end
        return false
    end

    -- ============================================================
    -- ★★★ 核心防线 1：拿"真实基础武器ID" ★★★
    -- 永远只信任 GetItemDefineID().TypeSpecificID（这是物品定义，不是皮肤）
    -- 绝不信任 synData[7] 或 GetWeaponID（可能是被污染过的皮肤ID）
    -- ============================================================
    local function getRealBaseWeaponID(w)
        if not w or not slua.isValid(w) then return 0 end

        local wid = 0

        -- ① 首选：物品定义ID（最权威）
        pcall(function()
            local did = w:GetItemDefineID()
            if did and did.TypeSpecificID then
                wid = did.TypeSpecificID
            end
        end)

        -- ② 兜底：GetWeaponID
        if wid <= 0 then
            pcall(function() wid = w:GetWeaponID() or 0 end)
        end

        if wid <= 0 then return 0 end

        -- ③ 归到底座
        local base = wid
        if _G.getBaseWeaponID then
            local ok, b = pcall(_G.getBaseWeaponID, wid)
            if ok and b and b > 0 then base = b end
        end
        return base
    end

    -- ============================================================
    -- ★★★ 核心防线 2：严格白名单判定"是不是真近战" ★★★
    -- 只认 {108001, 108004, 108005} 这三个底座
    -- 任何 101xxx~107xxx 段的枪械一律 false
    -- ============================================================
    local function isActuallyMeleeWeapon(w)
        local base = getRealBaseWeaponID(w)
        return base > 0 and MELEE_BASE[base] ~= nil
    end

    -- ============ 皮肤/武器ID → 近战底座 ============
    local function getMeleeBaseId(wid, ctxBase)
        wid = tonumber(wid) or 0
        if wid <= 0 then return nil end
        if not isMeleeWeaponId(wid) then return nil end
        if wid == 1081201 then return ctxBase or 108004 end
        if MELEE_BASE[wid] then return wid end
        if MELEE_ID_BASE[wid] then return MELEE_ID_BASE[wid] end
        if MELEE_SKIN_BASE[wid] then return MELEE_SKIN_BASE[wid] end
        if wid >= 1080011 and wid <= 1089999 then
            local b = math.floor(wid / 10)
            if MELEE_BASE[b] then return b end
            if _G.WeaponIDSets then
                for _, idSet in pairs(_G.WeaponIDSets) do
                    if idSet[wid] then
                        for id in pairs(idSet) do
                            if MELEE_BASE[id] then return id end
                        end
                    end
                end
            end
        end
        if _G.getBaseWeaponID then
            local ok, base = pcall(_G.getBaseWeaponID, wid)
            if ok and base and MELEE_BASE[base] then return base end
        end
        if _G.WeaponIDSets then
            for _, idSet in pairs(_G.WeaponIDSets) do
                if idSet[wid] then
                    for id in pairs(idSet) do
                        if MELEE_BASE[id] then return id end
                    end
                end
            end
        end
        if wid >= 1108001001 and wid <= 1108001999 then return 108001 end
        if wid >= 1108004001 and wid <= 1108004999 then return 108004 end
        if wid >= 1108005001 and wid <= 1108005999 then return 108005 end
        return nil
    end

    -- ============================================================
    -- ★★★ 核心防线 3：applyToWeapon 里再断言一次"w 必须是真近战" ★★★
    -- 三道锁齐上：targetSkin 是近战皮肤 + w 是真近战 + 数据合法
    -- ============================================================
    local function applyToWeapon(w, targetSkin)
        if not w or not slua.isValid(w) then return false end

        -- 锁 1：目标皮肤必须落在近战皮肤段
        if not isMeleeSkin(targetSkin) then return false end
        targetSkin = tonumber(targetSkin) or 0
        if targetSkin <= 0 then return false end

        -- 锁 2：★ 终极断言：w 本身必须是真近战，不是枪！★
        if not isActuallyMeleeWeapon(w) then
            return false
        end

        -- 锁 3：数据结构必须完整
        local arr = w.synData
        if not arr or not slua.isValid(arr) then return false end
        local d = arr:Get(7)
        if not d or not slua.isValid(d) then return false end
        local cur = slua.IndexReference(d, "defineID").TypeSpecificID
        if cur == targetSkin then return false end

        slua.IndexReference(d, "defineID").TypeSpecificID = targetSkin
        arr:Set(7, d)

        pcall(function() w:DelayHandleAvatarMeshChanged() end)
        pcall(function()
            local wac = w.WeaponAvatarComponent
            if wac and slua.isValid(wac) then
                if wac.OnRep_AvatarId      then wac:OnRep_AvatarId()      end
                if wac.OnRep_AvatarChanged then wac:OnRep_AvatarChanged() end
                if wac.OnRep_SkinChanged   then wac:OnRep_SkinChanged()   end
                if wac.ChangeItemAvatar then
                    pcall(function() wac:ChangeItemAvatar(targetSkin, true) end)
                end
            end
        end)
        return true
    end

    local function tryOneWeapon(w, applied)
        if not w or not slua.isValid(w) then return end

        -- ★★★ 用"真实基础武器ID"判断，而不是 GetWeaponID ★★★
        -- GetWeaponID 有可能返回被污染的皮肤ID，导致误判成近战
        if not isActuallyMeleeWeapon(w) then
            return
        end

        local wid = getRealBaseWeaponID(w)
        if wid <= 0 then return end

        -- 记录上下文底座（用于 1108001xxx 共用段区分砍刀/匕首）
        local ctxBase = nil
        pcall(function()
            local ar = w.synData
            if ar and slua.isValid(ar) then
                local dd = ar:Get(7)
                if dd and slua.isValid(dd) then
                    local cc = slua.IndexReference(dd, "defineID").TypeSpecificID
                    if cc and MELEE_SKIN_BASE[cc] then ctxBase = MELEE_SKIN_BASE[cc] end
                end
            end
        end)

        local base = getMeleeBaseId(wid, ctxBase)
        if not base then return end -- 该武器底座不在近战白名单，直接跳过

        local target = (_G.WeaponSkinID and _G.WeaponSkinID[base]) or 0

        -- 自动清洗：配置里不小心写了 M416 皮肤ID → 强制清零，不污染近战
        if target > 0 and not isMeleeSkin(target) then
            _G.WeaponSkinID[base] = 0
            target = 0
        end

        -- 配置为 0（未设置）→ 检查是否被污染的皮肤，需要回刷原皮
        if target == 0 then
            local arr = w.synData
            if arr and slua.isValid(arr) then
                local d = arr:Get(7)
                if d and slua.isValid(d) then
                    local cur = slua.IndexReference(d, "defineID").TypeSpecificID
                    -- 只有当前显示的是"近战皮肤"（说明是被刷错的近战皮肤）才回刷
                    -- 枪械皮肤不会命中 isMeleeSkin，天然跳过
                    if cur ~= base and cur ~= wid and isMeleeSkin(cur) then
                        applyToWeapon(w, base)
                    end
                end
            end
            return
        end

        if applyToWeapon(w, target) then
            applied[1] = applied[1] + 1
        end
    end

    function M.Refresh()
        if not M.Enabled then return 0 end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return 0 end
        local ch = pc:GetPlayerCharacterSafety()
        if not ch or not slua.isValid(ch) then return 0 end

        local applied = { 0 }
        local seen = {}

        -- 路径 1：背包
        pcall(function()
            local wm = ch:GetWeaponManager()
            if not wm or not slua.isValid(wm) then return end
            local list = wm:GetAllInventoryWeaponList(false)
            if not list or not slua.isValid(list) then return end
            for i = 0, list:Num() - 1 do
                local w = list:Get(i)
                if w and slua.isValid(w) and not seen[w] then
                    seen[w] = true
                    tryOneWeapon(w, applied)
                end
            end
        end)

        -- 路径 2：手上
        pcall(function()
            local w = ch:GetCurrentWeapon()
            if w and slua.isValid(w) and not seen[w] then
                seen[w] = true
                tryOneWeapon(w, applied)
            end
        end)

        -- 路径 3：全图扫描（防漏）
        pcall(function()
            local UGS = import("GameplayStatics")
            local world = ch:GetWorld()
            if not slua.isValid(world) then return end
            for _, clsName in ipairs({ "WeaponBase", "STExtraWeaponBase", "BattleWeaponBase" }) do
                local ok, cls = pcall(import, clsName)
                if ok and cls then
                    local ok2, arr = pcall(function()
                        return UGS.GetAllActorsOfClass(world, cls, {})
                    end)
                    if ok2 and arr then
                        for i = 0, arr:Num() - 1 do
                            local w = arr:Get(i)
                            if w and slua.isValid(w) and not seen[w] then
                                local owner = nil
                                pcall(function() owner = w.Owner or w:GetOwner() end)
                                if owner == ch then
                                    seen[w] = true
                                    tryOneWeapon(w, applied)
                                end
                            end
                        end
                    end
                end
            end
        end)

        return applied[1]
    end

    -- 2 秒扫一次
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(M.TICK_SEC, function()
            pcall(function()
                local inGame = GameStatus and GameStatus.IsInFightingStatus
                    and GameStatus.IsInFightingStatus() == true
                if inGame then M.Refresh() end
            end)
        end, -1, 1)
    end

    -- 进对局加速补刷
    local _origRefresh = M.Refresh
    if _G.Mytimer_ticker then
        for _, _d in ipairs({ 0.2, 0.6, 1.2, 2.5 }) do
            _G.Mytimer_ticker.AddTimer(_d, function()
                pcall(function()
                    local inGame = GameStatus and GameStatus.IsInFightingStatus
                        and GameStatus.IsInFightingStatus() == true
                    if inGame then _origRefresh() end
                end)
            end, 1)
        end
    end
end

-- ==================== ★ 近战武器便利刷肤（绝对防御版 V2 · 彻底防枪械污染）★ ====================
_G.MeleeSkinRefresher = _G.MeleeSkinRefresher or {}
do
    local M = _G.MeleeSkinRefresher
    M._installed = true

    M.Enabled  = true
    M.TICK_SEC = 2.0

    -- 近战基础ID（唯一合法的近战底座白名单）
    local MELEE_BASE = {
        [108001] = "Machete",
        [108004] = "PAN",
        [108005] = "Dagger",
    }

    -- 近战 7 位变体 → 底座（1080041 → 108004 等）
    local MELEE_ID_BASE = {
        [108001] = 108001, [1080010] = 108001, [1080011] = 108001, [1080019] = 108001,
        [108004] = 108004, [1080040] = 108004, [1080041] = 108004, [1080042] = 108004,
        [1080043] = 108004, [1080044] = 108004, [1080049] = 108004,
        [108005] = 108005, [1080050] = 108005, [1080059] = 108005,
    }

    -- 近战皮肤 ID → 底座（用于共用皮肤段时区分，如 1108001xxx）
    local MELEE_SKIN_BASE = {
        [1108005052] = 108005, -- 清夜蝶吻匕首
        [1108004027] = 108004, -- 冰雪晶核
        [1108004416] = 108004, -- 焰舞折扇平底锅
        [1108004380] = 108004, -- 红莲哥斯拉平底锅
        [1108004283] = 108004, -- 至臻壁垒平底锅
        [1108004230] = 108004, -- 莎莉-Pan
        [1108001081] = 108001, -- 红莲战斧
        [1108001099] = 108001, -- Juan Soto 棒球棍
    }

    -- ============ 皮肤段判定 ============
    local function isMeleeSkin(skinId)
        skinId = tonumber(skinId) or 0
        if skinId <= 0 then return false end
        if MELEE_BASE[skinId] then return true end
        if MELEE_ID_BASE[skinId] then return true end
        if skinId == 1081201 then return true end
        if skinId >= 1108001001 and skinId <= 1108001999 then return true end
        if skinId >= 1108004001 and skinId <= 1108004999 then return true end
        if skinId >= 1108005001 and skinId <= 1108005999 then return true end
        return false
    end

    -- ============ ID 段判定（用户输入/配置ID 的合法性） ============
    local function isMeleeWeaponId(wid)
        wid = tonumber(wid) or 0
        if wid <= 0 then return false end
        if MELEE_BASE[wid] then return true end
        if wid == 1081201 then return true end
        if wid >= 108001 and wid <= 108999 then return true end
        if wid >= 1080011 and wid <= 1089999 then return true end
        if wid >= 1108001001 and wid <= 1108005999 then return true end
        return false
    end

    -- ============================================================
    -- ★★★ 核心防线 1：拿"真实基础武器ID" ★★★
    -- 永远只信任 GetItemDefineID().TypeSpecificID（这是物品定义，不是皮肤）
    -- 绝不信任 synData[7] 或 GetWeaponID（可能是被污染过的皮肤ID）
    -- ============================================================
    local function getRealBaseWeaponID(w)
        if not w or not slua.isValid(w) then return 0 end

        local wid = 0

        -- ① 首选：物品定义ID（最权威）
        pcall(function()
            local did = w:GetItemDefineID()
            if did and did.TypeSpecificID then
                wid = did.TypeSpecificID
            end
        end)

        -- ② 兜底：GetWeaponID
        if wid <= 0 then
            pcall(function() wid = w:GetWeaponID() or 0 end)
        end

        if wid <= 0 then return 0 end

        -- ③ 归到底座
        local base = wid
        if _G.getBaseWeaponID then
            local ok, b = pcall(_G.getBaseWeaponID, wid)
            if ok and b and b > 0 then base = b end
        end
        return base
    end

    -- ============================================================
    -- ★★★ 核心防线 2：严格白名单判定"是不是真近战" ★★★
    -- 只认 {108001, 108004, 108005} 这三个底座
    -- 任何 101xxx~107xxx 段的枪械一律 false
    -- ============================================================
    local function isActuallyMeleeWeapon(w)
        local base = getRealBaseWeaponID(w)
        return base > 0 and MELEE_BASE[base] ~= nil
    end

    -- ============ 皮肤/武器ID → 近战底座 ============
    local function getMeleeBaseId(wid, ctxBase)
        wid = tonumber(wid) or 0
        if wid <= 0 then return nil end
        if not isMeleeWeaponId(wid) then return nil end
        if wid == 1081201 then return ctxBase or 108004 end
        if MELEE_BASE[wid] then return wid end
        if MELEE_ID_BASE[wid] then return MELEE_ID_BASE[wid] end
        if MELEE_SKIN_BASE[wid] then return MELEE_SKIN_BASE[wid] end
        if wid >= 1080011 and wid <= 1089999 then
            local b = math.floor(wid / 10)
            if MELEE_BASE[b] then return b end
            if _G.WeaponIDSets then
                for _, idSet in pairs(_G.WeaponIDSets) do
                    if idSet[wid] then
                        for id in pairs(idSet) do
                            if MELEE_BASE[id] then return id end
                        end
                    end
                end
            end
        end
        if _G.getBaseWeaponID then
            local ok, base = pcall(_G.getBaseWeaponID, wid)
            if ok and base and MELEE_BASE[base] then return base end
        end
        if _G.WeaponIDSets then
            for _, idSet in pairs(_G.WeaponIDSets) do
                if idSet[wid] then
                    for id in pairs(idSet) do
                        if MELEE_BASE[id] then return id end
                    end
                end
            end
        end
        if wid >= 1108001001 and wid <= 1108001999 then return 108001 end
        if wid >= 1108004001 and wid <= 1108004999 then return 108004 end
        if wid >= 1108005001 and wid <= 1108005999 then return 108005 end
        return nil
    end

    -- ============================================================
    -- ★★★ 核心防线 3：applyToWeapon 里再断言一次"w 必须是真近战" ★★★
    -- 三道锁齐上：targetSkin 是近战皮肤 + w 是真近战 + 数据合法
    -- ============================================================
    local function applyToWeapon(w, targetSkin)
        if not w or not slua.isValid(w) then return false end

        -- 锁 1：目标皮肤必须落在近战皮肤段
        if not isMeleeSkin(targetSkin) then return false end
        targetSkin = tonumber(targetSkin) or 0
        if targetSkin <= 0 then return false end

        -- 锁 2：★ 终极断言：w 本身必须是真近战，不是枪！★
        if not isActuallyMeleeWeapon(w) then
            return false
        end

        -- 锁 3：数据结构必须完整
        local arr = w.synData
        if not arr or not slua.isValid(arr) then return false end
        local d = arr:Get(7)
        if not d or not slua.isValid(d) then return false end
        local cur = slua.IndexReference(d, "defineID").TypeSpecificID
        if cur == targetSkin then return false end

        slua.IndexReference(d, "defineID").TypeSpecificID = targetSkin
        arr:Set(7, d)

        pcall(function() w:DelayHandleAvatarMeshChanged() end)
        pcall(function()
            local wac = w.WeaponAvatarComponent
            if wac and slua.isValid(wac) then
                if wac.OnRep_AvatarId      then wac:OnRep_AvatarId()      end
                if wac.OnRep_AvatarChanged then wac:OnRep_AvatarChanged() end
                if wac.OnRep_SkinChanged   then wac:OnRep_SkinChanged()   end
                if wac.ChangeItemAvatar then
                    pcall(function() wac:ChangeItemAvatar(targetSkin, true) end)
                end
            end
        end)
        return true
    end

    local function tryOneWeapon(w, applied)
        if not w or not slua.isValid(w) then return end

        -- ★★★ 用"真实基础武器ID"判断，而不是 GetWeaponID ★★★
        -- GetWeaponID 有可能返回被污染的皮肤ID，导致误判成近战
        if not isActuallyMeleeWeapon(w) then
            return
        end

        local wid = getRealBaseWeaponID(w)
        if wid <= 0 then return end

        -- 记录上下文底座（用于 1108001xxx 共用段区分砍刀/匕首）
        local ctxBase = nil
        pcall(function()
            local ar = w.synData
            if ar and slua.isValid(ar) then
                local dd = ar:Get(7)
                if dd and slua.isValid(dd) then
                    local cc = slua.IndexReference(dd, "defineID").TypeSpecificID
                    if cc and MELEE_SKIN_BASE[cc] then ctxBase = MELEE_SKIN_BASE[cc] end
                end
            end
        end)

        local base = getMeleeBaseId(wid, ctxBase)
        if not base then return end -- 该武器底座不在近战白名单，直接跳过

        local target = (_G.WeaponSkinID and _G.WeaponSkinID[base]) or 0

        -- 自动清洗：配置里不小心写了 M416 皮肤ID → 强制清零，不污染近战
        if target > 0 and not isMeleeSkin(target) then
            _G.WeaponSkinID[base] = 0
            target = 0
        end

        -- 配置为 0（未设置）→ 检查是否被污染的皮肤，需要回刷原皮
        if target == 0 then
            local arr = w.synData
            if arr and slua.isValid(arr) then
                local d = arr:Get(7)
                if d and slua.isValid(d) then
                    local cur = slua.IndexReference(d, "defineID").TypeSpecificID
                    -- 只有当前显示的是"近战皮肤"（说明是被刷错的近战皮肤）才回刷
                    -- 枪械皮肤不会命中 isMeleeSkin，天然跳过
                    if cur ~= base and cur ~= wid and isMeleeSkin(cur) then
                        applyToWeapon(w, base)
                    end
                end
            end
            return
        end

        if applyToWeapon(w, target) then
            applied[1] = applied[1] + 1
        end
    end

    function M.Refresh()
        if not M.Enabled then return 0 end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return 0 end
        local ch = pc:GetPlayerCharacterSafety()
        if not ch or not slua.isValid(ch) then return 0 end

        local applied = { 0 }
        local seen = {}

        -- 路径 1：背包
        pcall(function()
            local wm = ch:GetWeaponManager()
            if not wm or not slua.isValid(wm) then return end
            local list = wm:GetAllInventoryWeaponList(false)
            if not list or not slua.isValid(list) then return end
            for i = 0, list:Num() - 1 do
                local w = list:Get(i)
                if w and slua.isValid(w) and not seen[w] then
                    seen[w] = true
                    tryOneWeapon(w, applied)
                end
            end
        end)

        -- 路径 2：手上
        pcall(function()
            local w = ch:GetCurrentWeapon()
            if w and slua.isValid(w) and not seen[w] then
                seen[w] = true
                tryOneWeapon(w, applied)
            end
        end)

        -- 路径 3：全图扫描（防漏）
        pcall(function()
            local UGS = import("GameplayStatics")
            local world = ch:GetWorld()
            if not slua.isValid(world) then return end
            for _, clsName in ipairs({ "WeaponBase", "STExtraWeaponBase", "BattleWeaponBase" }) do
                local ok, cls = pcall(import, clsName)
                if ok and cls then
                    local ok2, arr = pcall(function()
                        return UGS.GetAllActorsOfClass(world, cls, {})
                    end)
                    if ok2 and arr then
                        for i = 0, arr:Num() - 1 do
                            local w = arr:Get(i)
                            if w and slua.isValid(w) and not seen[w] then
                                local owner = nil
                                pcall(function() owner = w.Owner or w:GetOwner() end)
                                if owner == ch then
                                    seen[w] = true
                                    tryOneWeapon(w, applied)
                                end
                            end
                        end
                    end
                end
            end
        end)

        return applied[1]
    end

    -- 2 秒扫一次
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(M.TICK_SEC, function()
            pcall(function()
                local inGame = GameStatus and GameStatus.IsInFightingStatus
                    and GameStatus.IsInFightingStatus() == true
                if inGame then M.Refresh() end
            end)
        end, -1, 1)
    end

    -- 进对局加速补刷
    local _origRefresh = M.Refresh
    if _G.Mytimer_ticker then
        for _, _d in ipairs({ 0.2, 0.6, 1.2, 2.5 }) do
            _G.Mytimer_ticker.AddTimer(_d, function()
                pcall(function()
                    local inGame = GameStatus and GameStatus.IsInFightingStatus
                        and GameStatus.IsInFightingStatus() == true
                    if inGame then _origRefresh() end
                end)
            end, 1)
        end
    end
end

-- ==================== ★ 大厅主题切换自动刷新载具补丁 ★ ====================
-- 当你在游戏里切换大厅主题时，立刻重新应用一次载具皮肤
pcall(function()
    if _G.__WM_ThemeChangeHookInstalled then return end
    _G.__WM_ThemeChangeHookInstalled = true

    local _lastThemeItem = -1
    local _lastThemeInst = -1

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                -- 只有在大厅才生效
                if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then return end
                
                -- 拿当前主题数据（★性能：模块只 require 一次，不每秒调用）
                if _G.__hThemeMod == nil then
                    local okm, mm = pcall(require, "client.logic.lobby.hall_theme_utils")
                    _G.__hThemeMod = (okm and mm) or false
                end
                local m = _G.__hThemeMod
                if not m then return end
                
                local curItem = tonumber(m.homeThemeItemId) or 0
                local curInst = tonumber(m.homeThemeInstId) or 0

                -- 初始化记录
                if _lastThemeItem == -1 then
                    _lastThemeItem = curItem
                    _lastThemeInst = curInst
                    return
                end

                -- 检测到主题变化
if curItem ~= _lastThemeItem or curInst ~= _lastThemeInst then
    _lastThemeItem = curItem
    _lastThemeInst = curInst
    
    -- ★★★ 核心修复：切换主题时，开启保护锁 3 秒，阻止 HairGuard 强行改写模型数据 ★★★
    _G.__IsThemeSwitching = true
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(2.0, function()
            _G.__IsThemeSwitching = false
            -- 主题加载完后，安全地补刷一次
            pcall(_G.LobbyVehicleRefresh)
            if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                pcall(_G.Wumingking.ApplyToLobby, true)
            end
        end)
    end

    -- 黑名单主题直接跳过（保障原生安全）
    if curItem == 202408061 or curItem == 202408087 then return end
                    
                    -- 切换主题后，延迟 1 秒等模型加载完，再刷载具
                    if _G.Mytimer_ticker then
                        _G.Mytimer_ticker.AddTimer(1.0, function()
                            pcall(_G.LobbyVehicleRefresh) -- 只执行刷新
                        end)
                    end
                end
            end)
        end, -1, 1)
    end
end)


-- ============================================================
-- 地铁仓库数据层拦截（完美解决地铁大厅武器皮肤同步）
-- 核心：拦截 TxMission 模块，直接篡改底层物品表，绕过渲染层重置
-- ============================================================
pcall(function()
    if _G.__txMissionPatched then return end
    _G.__txMissionPatched = true

    -- 核心逻辑：直接篡改数据源
    local function patchItemData(t)
        if type(t) ~= "table" then return end
        local iid = tonumber(t.itemID)
        local sid = tonumber(t.skinID)
        
        -- 必须是合法的武器ID范围
        if iid and iid > 999999 and iid < 1e15 then
            local classic = nil
            if iid < 9999999 then
                -- 7位数及以下（变体ID），去掉尾数
                classic = math.floor(iid / 10)
            else
                -- 8位以上（皮肤ID），用自带的转换函数
                classic = _G.getBaseWeaponID and _G.getBaseWeaponID(iid) or nil
            end
            
            -- 确保拿到的是基础武器ID，并且配置了假皮肤
            if classic and classic ~= iid and classic >= 100000 and classic <= 999999 then
                local fakeSkin = _G.WeaponSkinID and _G.WeaponSkinID[classic]
                if fakeSkin and fakeSkin > 0 then
                    -- 抢在游戏渲染前，强行写死假皮肤
                    t.skinID = fakeSkin
                end
            end
        end
    end

    -- 深度 Hook 地铁模块
    local function hookTxMission()
        for path, mod in pairs(package.loaded) do
            if type(path) == "string" and (path:find("TxMission") or path:find("logic_xmission")) then
                if type(mod) == "table" and not rawget(mod, "__txm_hooked") then
                    rawset(mod, "__txm_hooked", true)
                    
                    -- 遍历模块里所有函数
                    for k, v in pairs(mod) do
                        if type(k) == "string" and type(v) == "function" and not k:match("^_") then
                            local orig = v
                            mod[k] = function(self, arg1, ...)
                                -- 如果传入的是 table，就尝试篡改
                                if type(arg1) == "table" then
                                    patchItemData(arg1)
                                end
                                return orig(self, arg1, ...)
                            end
                        end
                    end
                end
            end
        end
    end

    -- 挂载定时器，持续监控新加载的模块
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(hookTxMission)
        end, -1, 1)
    end
    
    hookTxMission()
end)



-- ==================== 地铁背包皮肤终极拦截（精准防重叠） ====================
do
    local function GetFakeBagSkin()
        for i = 1, 6 do
            local v = _G["Backpack"..i.."Skin"]
            if v and v > 0 then return v end
        end
        return 0
    end

    local _hooked = false
    local function HookMCAC()
        if _hooked then return true end
        pcall(function()
            local ok, MCAC = pcall(require, "GameLua.Mod.TPlan.Component.MetroCharacterAvatarComponent")
            if not ok or not MCAC then return end
            local impl = MCAC.__inner_impl
            if not impl or impl.__bagFinalHooked then _hooked = true; return end
            impl.__bagFinalHooked = true

            -- 1. 拦截获取基础皮肤 ID
            local orig_Get = impl.GetLocalEquipmentSkinID
            if type(orig_Get) == "function" then
                impl.GetLocalEquipmentSkinID = function(self, slotID, ...)
                    local ok2, r = pcall(orig_Get, self, slotID, ...)
                    if slotID == 8 then
                        local fake = GetFakeBagSkin()
                        if fake > 0 then return fake end
                    end
                    return ok2 and r or nil
                end
            end

            -- 2. 拦截等级替换 ID
            local orig_Level = impl.GetReplaceSkinIDByLevel
            if type(orig_Level) == "function" then
                impl.GetReplaceSkinIDByLevel = function(self, skinID, level, ...)
                    local fake = GetFakeBagSkin()
                    if fake > 0 and skinID == fake then return fake end
                    if fake > 0 and skinID == 1501003350 then return fake end
                    local ok2, r = pcall(orig_Level, self, skinID, level, ...)
                    return ok2 and r or nil
                end
            end

            -- 3. 拦截最终应用的高等级 Avatar（终极防线）
            local orig_High = impl.GetReplaceHighLvEquipmentAvatar
            if type(orig_High) == "function" then
                impl.GetReplaceHighLvEquipmentAvatar = function(self, slotID, resID, addID, ...)
                    -- 严格限制：只有 slotID == 8 才是背包！
                    if slotID == 8 then
                        local fake = GetFakeBagSkin()
                        if fake > 0 then return fake end
                    end
                    local ok2, r = pcall(orig_High, self, slotID, resID, addID, ...)
                    return ok2 and r or nil
                end
            end
            _hooked = true
        end)
        return _hooked
    end

    HookMCAC()

    -- 辅助：同步 SlotSyncData，确保背包 UI 也显示正确
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                if not _hooked then HookMCAC() end
                -- ★性能：没有目标皮肤就不取角色链路，直接跳过
                local target = GetFakeBagSkin()
                if target <= 0 then return end
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local ch = pc and pc:GetPlayerCharacterSafety()
                local comp = ch and ch.AvatarComponent2
                local ad = comp and comp.NetAvatarData and comp.NetAvatarData.SlotSyncData
                if ad then
                    if target > 0 then
                        for i = 0, ad:Num() - 1 do
                            local e = ad:Get(i)
                            if e and e.SlotID == 8 and e.ItemId ~= target then
                                e.ItemId = target
                                ad:Set(i, e)
                            end
                        end
                    end
                end
            end)
        end, -1, 1)
    end
end


-- ============================================================
-- v10（修复版·中文）：个人资料页 → 头像 / 头像框 选择
-- 说明：
--   1. 列表里的 ID 会按“已拥有”状态注入；
--   2. 选择不会发给服务器，只在本机生效；
--   3. 选择结果保存在 BeysaProfile.ini；
--   4. 全部代码放在 do ... end 里，避免超 200 个 local 限制。
-- 修复记录：
--   ① 补上 self 参数（原代码少传一个参数导致整个 hook 失效）
--   ② expire_time=1 改成未来时间戳（否则一进页面就判过期）
--   ③ BeysaFake 缺失时自动兜底（否则整块代码崩溃）
--   ④ F.later 改成 Mytimer_ticker / common.time_ticker 重试
--   ⑤ 用独立变量 _G.__BeysaUserAvatarPick / _G.__BeysaUserFramePick
--      记录用户在本脚本 Hook 里的选择，防止被 refresh_basic_data 回写覆盖
--   ⑥ on_change_user_avatar_rsp / on_change_avatar_box_rsp 必须点号调用
-- ============================================================
do
    -- ============ ① BeysaFake 兜底（防止整块崩溃） ============
    if not _G.BeysaFake then
        local _fakeAvatar, _fakeBox = 0, 0
        _G.BeysaFake = {
            GetProfile   = function() return _fakeAvatar, _fakeBox end,
            SetAvatar    = function(id) _fakeAvatar = tonumber(id) or 0 end,
            SetAvatarBox = function(id) _fakeBox    = tonumber(id) or 0 end,
        }
    end

    -- ★★★ 独立变量初始化（供 _resolveAvatarIds 优先读取）
    _G.__BeysaUserAvatarPick = _G.__BeysaUserAvatarPick or 0
    _G.__BeysaUserFramePick  = _G.__BeysaUserFramePick  or 0

    -- ============ 头像 ID 列表（原样保留） ============
    local AVATAR_IDS = {
        30019, 30023, 30024, 30055, 30056, 30057, 30058, 30059, 30063, 30064, 30065, 30066,
        30067, 30068, 30069, 30070, 30071, 30072, 30073, 30074, 30076, 30077, 30078, 30080,
        30081, 30082, 30083, 30084, 30085, 30086, 30087, 30088, 30089, 30091, 30093, 30096,
        30097, 30099, 30100, 30110, 30113, 30114, 30115, 30120, 30121, 30124, 30126, 30127,
        30130, 30131, 30132, 30133, 30134, 30135, 30136, 30137, 30138, 30139, 30143, 30153,
        30154, 30155, 30160, 30161, 30162, 30165, 30166, 30167, 30168, 30169, 30170, 30171,
        30172, 30173, 30174, 30175, 30176, 30177, 30178, 30179, 30180, 30181, 30182, 30183,
        30184, 30185, 30186, 30188, 30189, 30191, 30192, 30193, 30194, 30195, 30196, 30197,
        30199, 30200, 30201, 30202, 30203, 30204, 30205, 30206, 30207, 30208, 30209, 30210,
        30211, 30212, 30213, 30214, 30215, 30216, 30217, 30218, 30219, 30220, 30221, 30222,
        30223, 30224, 30225, 30226, 30227, 30228, 30229, 30230, 30231, 30232, 30233, 30234,
        30235, 30236, 30237, 30238, 30239, 30240, 30241, 30242, 30243, 30244, 30245, 30246,
        30247, 30248, 30249, 30250, 30251, 30252, 30253, 30254, 30255, 30256, 30257, 30258,
        30259, 30260, 30261, 30262, 30263, 30264, 30265, 30266, 30267, 30268, 30269, 30270,
        30271, 30272, 30273, 30274, 30275, 30276, 30277, 30278, 30279, 30280, 30281, 30282,
        30283, 30284, 30285, 30286, 30287, 30288, 30289, 30290, 30291, 30292, 30293, 30294,
        30295, 30296, 30297, 30298, 30299, 30300, 30301, 30302, 30303, 30304, 30305, 30306,
        30307, 30308, 30309, 30310, 30311, 30312, 30313, 30314, 30315, 30316, 30317, 30318,
        30319, 30320, 30321, 30322, 30323, 30324, 30325, 30326, 30327, 30328, 30329, 30330,
        30331, 30332, 30333, 30334, 30335, 30336, 30337, 30338, 30339, 30340, 30341, 30342,
        30343, 30344, 30345, 30346, 30347, 30348, 30349, 30350, 30351, 30352, 30353, 30354,
        30355, 30356, 30357, 30358, 30359, 30360, 30361, 30362, 30363, 30364, 30365, 30366,
        30367, 30368, 30369, 30370, 30371, 30372, 30373, 30374, 30375, 30376, 30377, 30378,
        30379, 30380, 30381, 30382, 30383, 30384, 30385, 30386, 30387, 30388, 30389, 30390,
        30391, 30392, 30393, 30394, 30395, 30396, 30397, 30398, 30400, 30401, 30402, 30403,
        30404, 30405, 30406, 30407, 30408, 30409, 30410, 30411, 30412, 30413, 30414, 30415,
        30416, 30417, 30418, 30419, 30420, 30421, 30422, 30423, 30424, 30601, 30602, 30603,
        30604, 30605, 30606, 30607, 30608, 30609, 30610, 30611, 30612, 30613, 30614, 30615,
        30616, 30617, 30618, 30619, 30620, 30621, 30622, 30623, 30624, 30625, 30626, 30627,
        30628, 30629, 30630, 30631, 30632, 30633, 30634, 30635, 30636, 30637, 30638, 30639,
        30640, 31001, 31003, 31004, 31005, 31006, 31007, 31008, 31009, 31010, 31011, 31012,
        31013, 31014, 31015, 31016, 31017, 31018, 31019, 31020, 31021, 31022, 31023, 31024,
        31025, 31026, 31027, 31028, 31029, 31030, 31031, 31032, 31033, 31034, 31035, 31036,
        31037, 31038, 31039, 31040, 31041, 31042, 31043, 31044, 31045, 31046, 31047, 31048,
        31049, 31051, 31052, 31053, 31054, 31055, 31056, 31057, 31058, 31059, 31060, 31061,
        31062, 31063, 31064, 31065, 31066, 31067, 31068, 31069, 31070, 31071, 31072, 31073,
        31074, 31075, 31076, 31077, 31078, 31079, 31080, 31081, 31082, 31083, 31084, 31085,
        31086, 31087, 31088, 31089, 31090, 31091, 31092, 31093, 31094, 31095, 31096, 31097,
        31098, 31099, 31100, 31101, 31102, 31103, 31104, 31105, 31106, 31107, 31108, 31109,
        31110, 31111, 31112, 31113, 31114, 31115, 31116, 31117, 31118, 31119, 31120, 31122,
        31123, 31124, 31125, 31126, 31127, 31128, 31129, 31130, 31131, 31132, 31133, 31134,
        31135, 31136, 31137, 31138, 31139, 31140, 31141, 31142, 31143, 31144, 31145, 31146,
        31147, 31148, 31149, 31150, 31151, 31152, 31153, 31154, 31155, 31156, 31157, 31158,
        31159, 31160, 31161, 31162, 31163, 31164, 31165, 31166, 31167, 31168, 31169, 31170,
        31171, 31172, 31173, 31174, 31175, 31176, 31177, 31178, 31179, 31180, 31181, 31182,
        31183, 31184, 31185, 31186, 31187, 31188, 31189, 31190, 31191, 31192, 31194, 31195,
        31196, 31197, 31198, 31199, 31200, 31201, 31202, 31203, 31204, 31205, 31206, 31207,
        31209, 31210, 31211, 31212, 31213, 31214, 31215, 31216, 31217, 31218, 31219, 31220,
        31221, 31222, 31225, 31226, 31227, 31228, 31229, 31230, 31231, 31234, 31236, 31237,
        31238, 31239, 31240, 31241, 31242, 31243, 31244, 31245, 31246, 31250, 31251, 31252,
        31253, 31254, 31255, 31256, 31257, 31258, 31259, 31260, 31261, 31262, 31264, 31265,
        31266, 31267, 31268, 31269, 31270, 31271, 31272, 31273, 31274, 31275, 31276, 31277,
        31278, 31279, 31280, 31281, 31282, 31283, 31284, 31287, 31290, 31291, 31292, 31293,
        31294, 31295, 31296, 31297, 31298, 31299, 31300, 31303, 31304, 31305, 31312, 31313,
        31315, 31316, 31318, 31319, 31320, 31321, 31322, 31323, 31324, 31325, 31326, 31327,
        31328, 31330, 31331, 31332, 31333, 31334, 31335, 31364, 31400, 31401, 31403, 31404,
        31405, 31410, 31411, 31412, 31413, 31414, 31415, 31430, 31431, 31432, 31433, 31434,
        31437, 31438, 31439, 31441, 31442, 31443, 31444, 31445, 31446, 31447, 31448, 31449,
        31451, 31452, 31453, 31454, 31455, 31456, 31457, 31459, 31460, 31461, 31462, 31465,
        31466, 31467, 31468, 31470, 31475, 31476, 31477, 31501, 31502, 31503, 31504, 31505,
        31506, 31507, 31508, 31509, 31510, 31511, 31512, 31513, 31514, 31515, 31516, 32002,
        32003, 32004, 32005, 32006, 32007, 32008, 32009, 32010, 32011, 35001, 35002, 35003,
        35004, 35005, 35006, 35007, 35008, 35009, 35010, 40001, 40002, 40004, 40005, 40007,
        40008, 40010, 40011, 40013, 40014, 40016, 40017, 40019, 40020, 40022, 40023, 40025,
        40026, 40028, 40029, 40031, 40032, 40034, 40035, 40037, 40038, 40040, 40041, 40043,
        40044, 40046, 40047, 40049, 40050, 40232, 40233, 40242, 40243, 40252, 40253, 40262,
        40263, 60001, 60003, 60005, 60007, 60009, 60011, 60013, 60015, 60017, 60019, 60021,
        60023, 60025, 60027, 60029, 60031, 60033, 60035, 60037, 60039, 60041, 60043, 60044,
        60046, 60048, 60050, 60052, 60054, 60056, 60058, 60060, 60062, 60064, 60066, 60068,
        60070, 60072, 60074, 60076, 60078, 70001, 70002, 70003, 70004, 70005, 70006, 70007,
        70008, 70009, 70010, 70011, 70012, 1522195, 1522196, 1522240, 1522329, 1540259, 2000103, 2000104,
        2000105, 2001000, 2001001, 2001002, 2001003, 2001004, 2001005, 2001006, 2001007, 2001008, 2001009, 2001010,
        2001011, 2001012, 2001013, 2001014, 2001015, 2001016, 2001017, 2001018, 2001019, 2001020, 2001021, 2001022,
        2001023, 2001024, 2001025, 2001026, 2001027, 2001028, 2001029, 2001030, 2001031, 2001032, 2001033, 2001034,
        2001035, 2001036, 2001037, 2001038, 2001039, 2001040, 2001041, 2001042, 2001043, 2001044, 2001045, 2001046,
        2001047, 2001048, 2001049, 2001050, 2001051, 2001052, 2001053, 2001054, 2001055, 2001056, 2001057, 2001058,
        2001059, 2001060, 2001061, 2001062, 2001063, 2001064, 2001065, 2001066, 2001067, 2001068, 2001069, 2001070,
        2001071, 2001072, 2001073, 2001074, 2001075, 2001076, 2001079, 2001080, 2001081, 2001082, 2001083, 2001084,
        2001085, 2001086, 2001087, 2001088, 2001089, 2001090, 2001091, 2001092, 2001093, 2001094, 2001095, 2001096,
        2001097, 2001098, 2001099, 2001100, 2001101, 2001102, 2001103, 2001104, 2001105, 2001106, 2001107, 2001108,
        2001109, 2001110, 2001111, 2001112, 2001113, 2001114, 2001115, 2001116, 2001117, 2001118, 2001119, 2001120,
        2001121, 2001122, 2001123, 2001124, 2001125, 2001126, 2001127, 2001128, 2001129, 2001130, 2001131, 2001132,
        2001133, 2001134, 2001135, 2001136, 2001137, 2001138, 2001139, 2001140, 2001141, 2001142, 2001143, 2001144,
        2001145, 2001146, 2001147, 2001148, 2001149, 2001150, 2001151, 2001152, 2001153, 2001154, 2001155, 2001156,
        2001157, 2001158, 2001159, 2001160, 2001161, 2001162, 2001163, 2001164, 2001165, 2001166, 2001169, 2001170,
        2001171, 2001172, 2001173, 2001174, 2001175, 2001176, 2001177, 2001178, 2001179, 2001180, 2001181, 2001182,
        2001183, 2001184, 2001185, 2001186, 2001187, 2001188, 2001189, 2001190, 2001191, 2001193, 2001194, 2001195,
        2001196, 2001197, 2001198, 2001199, 2001200, 2001201, 2001202, 2001203, 2001204, 2001205, 2001206, 2001207,
        2001208, 2001209, 2001210, 2001211, 2001212, 2001213, 2001214, 2001215, 2001216, 2001217, 2001218, 2001219,
        2001220, 2001221, 2001222, 2001223, 2001224, 2002000, 2002101, 2002102, 2002103, 2002201, 2002202, 2002203,
        2002204, 2002205, 2002206, 2002901, 2002902, 2002903, 2002904, 2002905, 2002906, 2002907, 2002920, 2002921,
        2002922, 2002923, 2002924, 2002925, 2002926, 2002927, 2002928, 2002929, 2002930, 2002931, 2002932, 2002933,
        2002934, 2002935, 2002936, 2002937, 2002938, 2002939, 2002940, 2002941, 2002942, 2002943, 2002944, 2002945,
        2002946, 2002947, 2002948, 2002949, 2002950, 2002951, 2002952, 2002965, 2002966, 2002967, 2002968, 2002969,
        2002970, 2003000, 2003001, 2003002, 2003003, 2003004, 2003005, 2003006, 2003007, 2003008, 2003009, 2003010,
        2003011, 2003012, 2003013, 2003014, 2003015, 2003016, 2003017, 2003018, 2003019, 2003020, 2003021, 2003022,
        2003023, 2003024, 2003025, 2003026, 2003027, 2003028, 2003029, 2004006, 2005001, 2005002, 2005003, 2005007,
        2005008, 2005009, 2005023, 2005024, 2005025, 2005028, 2005031, 2005034, 2005038, 2005041, 2005043, 2005047,
        2005048, 2005049, 2005050, 2005051, 2005052, 2005053, 2005058, 2005059, 2005060, 2005062, 2005063, 2005064,
        2005065, 2005066, 2005067, 2005068, 2005069, 2005070, 2005071, 2005072, 2005073, 2005074, 2005075, 2005076,
        2005078, 2005079, 2005080, 2005081, 2005082, 2005083, 2005084, 2005085, 2005086, 2005087, 2005088, 2005092,
        2005093, 2005094, 2005096, 2005097, 2005098, 2005099, 2005100, 2005101, 2005105, 2005106, 2005107, 2005108,
        2005111, 2005112, 2005113, 2005114, 2005115, 2005116, 2005117, 2005119, 2005123, 2005124, 2005125, 2005126,
        2005127, 2005128, 2005129, 2005130, 2005131, 2005132, 2005133, 2005134, 2005135, 2005136, 2005137, 2005138,
        2005139, 2005140, 2005141, 2005143, 2005144, 2005145, 2005147, 2005148, 2005149, 2005150, 2005151, 2005152,
        2005154, 2005155, 2005158, 2005159, 2005160, 2005161, 2005162, 2005163, 2005164, 2005165, 2005166, 2005167,
        2005168, 2005169, 2005170, 2005171, 2005172, 2005173, 2005174, 2005175, 2005176, 2005177, 2005178, 2005179,
        2005180, 2005181, 2005183, 2005184, 2005185, 2005186, 2005187, 2005188, 2005190, 2005191, 2005192, 2005193,
        2005194, 2005195, 2005196, 2005197, 2005198, 2005199, 2005200, 2005202, 2005203, 2005204, 2005205, 2005206,
        2005207, 2005208, 2005211, 2005212, 2005213, 2005214, 2005215, 2005216, 2005217, 2005218, 2005219, 2005220,
        2005221, 2005224, 2005225, 2005226, 2005227, 2005228, 2005237, 2005239, 2005245, 2005247, 2005248, 2005249,
        2005250, 2005251, 2005252, 2005253, 2005254, 2005255, 2005256, 2005257, 2005258, 2005259, 2005260, 2005261,
        2005262, 2005263, 2005264, 2005265, 2005266, 2005267, 2005268, 2005269, 2010001, 2010002, 2010003, 2010004,
        2010005, 2010006, 2010007, 2010008, 2010009, 2200002, 2200003, 2200004, 2200005, 2200006, 2200007, 2200008,
        2200009, 2200010, 2200011, 2200012, 2200013, 2200014, 2200015, 2200016, 2200017, 2200018, 2200019, 2200020,
        2200021, 2200022, 2200023, 2200024, 2200025, 2200026, 2200027, 2200028, 2200029, 2200030, 2200031, 2200032,
        2200033, 2200034, 2200035, 2200036, 2200037, 2200038, 2200039, 2200041, 2200043, 2200044, 2200045, 2200046,
        2200047, 2200048, 2200049, 2200050, 2200051, 2200052, 2200053, 2200054, 2200055, 2200056, 2200057, 2200058,
        2200059, 2200063, 2200064, 2200065, 2200066, 2200067, 2200068, 2200069, 2200070, 2200071, 2200072, 2200073,
        2200074, 2200075, 2200076, 2200077, 2200078, 2200079, 2200080, 2200081, 2200082, 2200083, 2200084, 2200085,
        2200086, 2200087, 2200088, 2200089, 2200090, 2200091, 2200092, 2200093, 2200094, 2200095, 2200096, 2200097,
        2200098, 2200099, 2200100, 2200102, 2200103, 2200104, 2200105, 2200107, 2200108, 2200110, 2200111, 2200112,
        2200113, 2200114, 2200115, 2200116, 2200118, 2200119, 2200120, 2200121, 2200123, 2200124, 2200125, 2200126,
        2200140, 2200141, 2200142, 2200143, 2200144, 2200158, 2200161, 2200167, 2200168, 2200169, 2200170, 2200171,
        2200172, 2200173, 2200174, 2200210, 2200211, 2200212, 2200217, 2200218, 2200219, 2200222, 2200223, 2200224,
        2200228, 2200229, 2200231, 2200232, 2200233, 2200235, 2200236, 2200237, 2200238, 2200239, 2200240, 2200241,
        2200244, 2200245, 2200246, 2200248, 2200249, 2200250, 2200253, 2200260, 2200261, 2200262, 2201048, 4507702,
        4507703, 12222958, 22001034, 22001036, 22001037, 22001038, 22001039, 22001044, 22001045, 22001049, 80080001, 80080002,
        80080003, 80080004, 80080005, 220010450, 220010451, 220010452, 220010453, 220010454, 220010455, 220010456, 220010457, 220010458,
        220010459, 220010460, 220010462, 220010492, 300000001, 300000002, 300000003, 300000004, 300000005, 300000006, 300000007, 300000008,
        300000009, 300000010, 300000011, 300000012, 300000013, 300000014, 300000015, 300000016, 300000017, 300000018, 300000019, 300000020,
        300000021, 300000022, 300000023, 300000024, 300000025, 300000026, 300010001, 300010002, 300010003, 300010004, 300010005,
    }

    -- ============ 头像框 ID 列表（原样保留） ============
    local FRAME_IDS = {
        30079, 30090, 30092, 30094, 30095, 30098, 30111, 30112, 30116, 30117, 30118, 30119,
        30122, 30123, 30125, 30128, 30129, 30130, 30142, 30143, 30144, 30145, 30146, 30147,
        30148, 30149, 30150, 30151, 30152, 30156, 30157, 30158, 30159, 30163, 30164, 30167,
        30168, 30169, 30176, 30177, 30185, 30186, 30191, 30194, 30195, 30202, 30204, 30216,
        30217, 30238, 30239, 30254, 30255, 30257, 30263, 30264, 30286, 30287, 30294, 30295,
        30298, 30299, 30300, 30301, 30302, 30303, 30306, 30307, 30309, 30312, 30313, 30314,
        30315, 30317, 30318, 30319, 30322, 30323, 30326, 30327, 30328, 30329, 30332, 30333,
        30334, 30335, 30338, 30341, 30342, 30343, 30344, 30345, 30346, 30349, 30350, 30351,
        30352, 30355, 30356, 30357, 30359, 30360, 30363, 30364, 30367, 30368, 30369, 30370,
        30373, 30374, 30375, 30376, 30377, 30380, 30381, 30382, 30383, 30386, 30387, 30388,
        30389, 30392, 30393, 30394, 30395, 30601, 30602, 30605, 30606, 30609, 30610, 30611,
        30612, 30615, 30616, 30617, 30618, 30621, 30622, 30623, 30624, 30625, 30627, 30630,
        30631, 30632, 30633, 30634, 30637, 30638, 30639, 30640, 31001, 31261, 40002, 40005,
        40008, 40011, 40014, 40017, 40020, 40023, 40026, 40029, 40032, 40035, 40038, 40041,
        40044, 40047, 40050, 60003, 60005, 60009, 60011, 60015, 60017, 60021, 60023, 60027,
        60029, 60033, 60035, 60039, 60041, 60043, 60046, 60048, 60052, 60054, 60058, 60060,
        60064, 60066, 60070, 60072, 60076, 60078, 70002, 70004, 70006, 70008, 70010, 70012,
        1403200, 1602266, 1602267, 2000103, 2000104, 2000105, 2001000, 2001001, 2001002, 2001003, 2001004, 2001005,
        2001006, 2001007, 2001008, 2001009, 2001010, 2001011, 2001012, 2001013, 2001014, 2001015, 2001016, 2001017,
        2001018, 2001019, 2001020, 2001021, 2001022, 2001023, 2001024, 2001025, 2001026, 2001027, 2001028, 2001029,
        2001030, 2001031, 2001032, 2001033, 2001034, 2001035, 2001036, 2001037, 2001038, 2001039, 2001040, 2001041,
        2001042, 2001043, 2001044, 2001045, 2001046, 2001047, 2001048, 2001049, 2001050, 2001051, 2001052, 2001053,
        2001054, 2001055, 2001056, 2001057, 2001058, 2001059, 2001060, 2001061, 2001062, 2001063, 2001064, 2001065,
        2001066, 2001067, 2001068, 2001069, 2001070, 2001071, 2001072, 2001073, 2001074, 2001075, 2001076, 2001079,
        2001080, 2001081, 2001082, 2001083, 2001084, 2001085, 2001086, 2001087, 2001088, 2001089, 2001090, 2001091,
        2001092, 2001093, 2001094, 2001095, 2001096, 2001097, 2001098, 2001099, 2001100, 2001101, 2001102, 2001103,
        2001104, 2001105, 2001106, 2001107, 2001108, 2001109, 2001110, 2001111, 2001112, 2001113, 2001114, 2001115,
        2001116, 2001117, 2001118, 2001119, 2001120, 2001121, 2001122, 2001123, 2001124, 2001125, 2001126, 2001127,
        2001128, 2001129, 2001130, 2001131, 2001132, 2001133, 2001134, 2001135, 2001136, 2001137, 2001138, 2001139,
        2001140, 2001141, 2001142, 2001143, 2001144, 2001145, 2001146, 2001147, 2001148, 2001149, 2001150, 2001151,
        2001152, 2001153, 2001154, 2001155, 2001156, 2001157, 2001158, 2001159, 2001160, 2001161, 2001162, 2001163,
        2001164, 2001165, 2001166, 2001169, 2001170, 2001171, 2001172, 2001173, 2001174, 2001175, 2001176, 2001177,
        2001178, 2001179, 2001180, 2001181, 2001182, 2001183, 2001184, 2001185, 2001186, 2001187, 2001188, 2001189,
        2001190, 2001191, 2001193, 2001194, 2001195, 2001196, 2001197, 2001198, 2001199, 2001200, 2001201, 2001202,
        2001203, 2001204, 2001205, 2001206, 2001207, 2001208, 2001209, 2001210, 2001211, 2001212, 2001213, 2001214,
        2001215, 2001216, 2001217, 2001218, 2001219, 2001220, 2001221, 2001222, 2001223, 2001224, 2002000, 2002001,
        2002002, 2002003, 2002004, 2002005, 2002006, 2002007, 2002101, 2002102, 2002103, 2002201, 2002202, 2002203,
        2002204, 2002205, 2002206, 2002901, 2002902, 2002903, 2002904, 2002905, 2002906, 2002907, 2002908, 2002909,
        2002910, 2002911, 2002912, 2002913, 2002914, 2002915, 2002916, 2002917, 2002918, 2002919, 2002920, 2002921,
        2002922, 2002923, 2002924, 2002925, 2002926, 2002927, 2002928, 2002929, 2002930, 2002931, 2002932, 2002933,
        2002934, 2002935, 2002936, 2002937, 2002938, 2002939, 2002940, 2002941, 2002942, 2002943, 2002944, 2002945,
        2002946, 2002947, 2002948, 2002949, 2002950, 2002951, 2002952, 2002965, 2002966, 2002967, 2002968, 2002969,
        2002970, 2003000, 2003001, 2003002, 2003003, 2003004, 2003005, 2003006, 2003007, 2003008, 2003009, 2003010,
        2003011, 2003012, 2003013, 2003014, 2003015, 2003016, 2003017, 2003018, 2003019, 2003020, 2003021, 2003022,
        2003023, 2003024, 2003025, 2003026, 2003027, 2003028, 2003029, 2004003, 2004005, 2004006, 2005001, 2005002,
        2005003, 2005004, 2005007, 2005008, 2005009, 2005010, 2005012, 2005013, 2005014, 2005015, 2005016, 2005017,
        2005018, 2005019, 2005020, 2005021, 2005022, 2005023, 2005024, 2005025, 2005026, 2005027, 2005028, 2005029,
        2005030, 2005031, 2005032, 2005033, 2005034, 2005035, 2005036, 2005037, 2005038, 2005039, 2005040, 2005041,
        2005042, 2005043, 2005044, 2005045, 2005046, 2005047, 2005048, 2005049, 2005050, 2005051, 2005052, 2005053,
        2005056, 2005057, 2005058, 2005059, 2005060, 2005061, 2005062, 2005063, 2005064, 2005065, 2005066, 2005067,
        2005068, 2005069, 2005070, 2005071, 2005072, 2005073, 2005074, 2005075, 2005076, 2005077, 2005078, 2005079,
        2005080, 2005081, 2005082, 2005083, 2005084, 2005085, 2005086, 2005087, 2005088, 2005089, 2005090, 2005091,
        2005092, 2005093, 2005094, 2005095, 2005096, 2005097, 2005098, 2005099, 2005100, 2005101, 2005102, 2005103,
        2005104, 2005105, 2005106, 2005107, 2005108, 2005111, 2005112, 2005113, 2005114, 2005115, 2005116, 2005117,
        2005118, 2005119, 2005120, 2005121, 2005122, 2005123, 2005124, 2005125, 2005126, 2005127, 2005128, 2005129,
        2005130, 2005131, 2005132, 2005133, 2005134, 2005135, 2005136, 2005137, 2005138, 2005139, 2005140, 2005141,
        2005142, 2005143, 2005144, 2005145, 2005146, 2005147, 2005148, 2005149, 2005150, 2005151, 2005152, 2005153,
        2005154, 2005155, 2005156, 2005157, 2005158, 2005159, 2005160, 2005161, 2005163, 2005164, 2005165, 2005166,
        2005167, 2005168, 2005169, 2005170, 2005171, 2005172, 2005173, 2005174, 2005175, 2005176, 2005177, 2005178,
        2005179, 2005180, 2005181, 2005182, 2005183, 2005184, 2005185, 2005186, 2005187, 2005188, 2005189, 2005190,
        2005191, 2005192, 2005193, 2005194, 2005195, 2005196, 2005197, 2005198, 2005199, 2005200, 2005201, 2005202,
        2005203, 2005204, 2005205, 2005206, 2005207, 2005208, 2005209, 2005210, 2005211, 2005212, 2005213, 2005214,
        2005215, 2005216, 2005217, 2005218, 2005219, 2005220, 2005221, 2005222, 2005223, 2005224, 2005225, 2005226,
        2005227, 2005228, 2005237, 2005239, 2005240, 2005241, 2005242, 2005243, 2005244, 2005245, 2005246, 2005247,
        2005248, 2005249, 2005250, 2005251, 2005252, 2005253, 2005254, 2005255, 2005256, 2005257, 2005258, 2005259,
        2005260, 2005261, 2005262, 2005263, 2005264, 2005265, 2005266, 2005267, 2005268, 2005269, 2010001, 2010002,
        2010003, 2010004, 2010005, 2010006, 2010007, 2010008, 2010009, 2200002, 2200003, 2200004, 2200005, 2200006,
        2200007, 2200008, 2200009, 2200010, 2200011, 2200012, 2200013, 2200014, 2200015, 2200016, 2200017, 2200018,
        2200019, 2200020, 2200021, 2200022, 2200023, 2200024, 2200025, 2200026, 2200027, 2200028, 2200029, 2200030,
        2200031, 2200032, 2200033, 2200034, 2200035, 2200036, 2200037, 2200038, 2200039, 2200040, 2200041, 2200043,
        2200044, 2200045, 2200046, 2200047, 2200048, 2200049, 2200050, 2200051, 2200052, 2200053, 2200054, 2200055,
        2200056, 2200057, 2200058, 2200059, 2200060, 2200063, 2200064, 2200065, 2200066, 2200067, 2200068, 2200069,
        2200070, 2200071, 2200072, 2200073, 2200074, 2200075, 2200076, 2200077, 2200078, 2200079, 2200080, 2200081,
        2200082, 2200083, 2200084, 2200085, 2200086, 2200087, 2200088, 2200089, 2200090, 2200091, 2200092, 2200093,
        2200094, 2200095, 2200096, 2200097, 2200098, 2200099, 2200100, 2200102, 2200103, 2200104, 2200105, 2200106,
        2200107, 2200108, 2200109, 2200110, 2200111, 2200112, 2200113, 2200114, 2200115, 2200116, 2200117, 2200118,
        2200119, 2200120, 2200121, 2200122, 2200123, 2200124, 2200125, 2200126, 2200140, 2200141, 2200142, 2200143,
        2200144, 2200145, 2200146, 2200147, 2200148, 2200149, 2200150, 2200151, 2200155, 2200156, 2200157, 2200158,
        2200161, 2200162, 2200163, 2200164, 2200165, 2200166, 2200167, 2200168, 2200169, 2200170, 2200171, 2200172,
        2200173, 2200174, 2200210, 2200211, 2200212, 2200213, 2200214, 2200216, 2200217, 2200218, 2200219, 2200220,
        2200221, 2200222, 2200223, 2200224, 2200225, 2200226, 2200227, 2200228, 2200229, 2200230, 2200231, 2200232,
        2200233, 2200234, 2200235, 2200236, 2200237, 2200238, 2200239, 2200240, 2200241, 2200242, 2200243, 2200244,
        2200245, 2200246, 2200248, 2200249, 2200250, 2200251, 2200252, 2200253, 2200256, 2200260, 2200261, 2200262,
        2201048, 4507703, 12219672, 12219673, 12220609, 12220611, 12222958, 22001034, 22001036, 22001037, 22001038, 22001039,
        22001040, 22001041, 22001042, 22001043, 22001044, 22001045, 22001047, 22001048, 22001049, 61830001, 61830002, 61830003,
        62310001, 62410001, 66631070, 66631704, 66631705, 66631706, 66631707, 66631708, 66631709, 66631710, 66632393, 220010450,
        220010451, 220010452, 220010453, 220010454, 220010455, 220010456, 220010457, 220010458, 220010459, 220010460, 220010462, 220010492,
        300000001, 300000002, 300000003, 300000004, 300000005, 300000006, 300000007, 300000008, 300000009, 300000010, 300000011, 300000012,
        300000013, 300000014, 300000015, 300000016, 300000017, 300000018, 300000019, 300000020, 300000021, 300000022, 300000023, 300000024,
        300000025, 300000026,
    }

    -- ============ 获取 BeysaFake 引用 ============
    local BF = _G.BeysaFake

    -- ============ 本地配置文件（保存已选头像/头像框） ============
    local PROFILE_INI = "/storage/emulated/0/Android/data/com.tencent.ig/files/BeysaProfile.ini"
    local function saveProfile()
        pcall(function()
            local a, b = BF.GetProfile()
            -- ★ 关键：优先写本脚本 Hook 记录的用户选择，防止 BF.GetProfile 返回服务器旧值
            if (_G.__BeysaUserAvatarPick or 0) > 0 then a = _G.__BeysaUserAvatarPick end
            if (_G.__BeysaUserFramePick  or 0) > 0 then b = _G.__BeysaUserFramePick  end
            local f = io.open(PROFILE_INI, "w")
            if not f then return end
            f:write("[Profile]\nAVATAR=" .. tostring(a or 0) ..
                    "\nFRAME="  .. tostring(b or 0) .. "\n")
            f:close()
        end)
    end

    -- ★ 包装原始设置函数：先更新独立变量（供 _resolveAvatarIds 优先读），再调原版，再写盘
    local rawSetAvatar, rawSetBox = BF.SetAvatar, BF.SetAvatarBox

    BF.SetAvatar = function(id)
        local n = tonumber(id) or 0
        if n > 0 then _G.__BeysaUserAvatarPick = n end
        rawSetAvatar(id)
        saveProfile()
    end

    BF.SetAvatarBox = function(id)
        local n = tonumber(id) or 0
        if n > 0 then _G.__BeysaUserFramePick = n end
        rawSetBox(id)
        saveProfile()
    end

    -- 启动时恢复上次选择：先写独立变量（供 _resolveAvatarIds 读），再调原版
    pcall(function()
        local f = io.open(PROFILE_INI, "r")
        if not f then return end
        local txt = f:read("*a"); f:close()
        local a = tonumber(txt:match("AVATAR%s*=%s*(%d+)"))
        local b = tonumber(txt:match("FRAME%s*=%s*(%d+)"))
        if a and a > 0 then
            _G.__BeysaUserAvatarPick = a
            rawSetAvatar(a)
        end
        if b and b > 0 then
            _G.__BeysaUserFramePick = b
            rawSetBox(b)
        end
    end)

    -- ============ 安全发送事件（模块缺失时自动跳过） ============
    local function post(evType, evId, arg1)
        pcall(function()
            if EventSystem and _G[evType] and _G[evId] then
                EventSystem:postEvent(_G[evType], _G[evId], arg1)
            end
        end)
    end

    -- ★★★ 核心修复：用 2033 年的时间戳（绝对不能用 49 亿，否则会触发 int32 溢出变成负数！）★★★
    local FOREVER_TS = 2000000000

    -- 已注入的 ID 集合（用于快速判定是否本地处理）
    local INJ_A, INJ_F = {}, {}

    -- ============ 把头像 ID 合并进头像列表 ============
    local function mergeAvatars(sys)
        sys.HeadportraitList = sys.HeadportraitList or {}

        -- ★★★ 核心：永久化工具函数（所有时限字段 = 未来时间戳）★★★
        local function makePermanent(template)
            local item = {}
            if type(template) == "table" then
                for kk, vv in pairs(template) do
                    item[kk] = vv
                end
            end
            rawset(item, "state",          1)
            rawset(item, "valid_hours",    0)
            rawset(item, "expire_time",    FOREVER_TS)
            rawset(item, "expire_ts",      FOREVER_TS)
            rawset(item, "expire_at",      FOREVER_TS)
            rawset(item, "expired_at",     FOREVER_TS)
            rawset(item, "receive_time",   os.time())
            rawset(item, "have_used",      1)
            rawset(item, "is_expired",     0)
            rawset(item, "expired",        false)
            return item
        end

        local template = nil
        local templateType = nil
        for _, v in pairs(sys.HeadportraitList) do
            if type(v) == "number" and v > 0 then
                template = v
                templateType = "number"
                break
            elseif type(v) == "table" then
                local st = tonumber(v.state) or 0
                local vh = tonumber(v.valid_hours)
                if st > 0 and vh == 0 then
                    template = v
                    templateType = "table"
                    break
                end
            end
        end

        local nAvatar = #AVATAR_IDS
        for i = 1, nAvatar do
            local id = AVATAR_IDS[i]
            local k = tostring(id)
            local existing = sys.HeadportraitList[k] or sys.HeadportraitList[id]
            if existing == nil then
                if templateType == "number" then
                    sys.HeadportraitList[k] = template
                else
                    sys.HeadportraitList[k] = makePermanent(templateType == "table" and template or nil)
                end
                INJ_A[k] = true
                INJ_A[id] = true
            elseif type(existing) == "table" then
                local function _fix(it)
                    if tonumber(it.state) ~= 1 then rawset(it, "state", 1) end
                    if tonumber(it.valid_hours or 0) ~= 0 then rawset(it, "valid_hours", 0) end
                    if tonumber(it.expire_time or 0) < FOREVER_TS then rawset(it, "expire_time", FOREVER_TS) end
                    if tonumber(it.expire_ts   or 0) < FOREVER_TS then rawset(it, "expire_ts",   FOREVER_TS) end
                    if tonumber(it.expire_at   or 0) < FOREVER_TS then rawset(it, "expire_at",   FOREVER_TS) end
                    if tonumber(it.expired_at  or 0) < FOREVER_TS then rawset(it, "expired_at",  FOREVER_TS) end
                    if tonumber(it.is_expired  or 0) ~= 0 then rawset(it, "is_expired", 0) end
                    if it.expired == true then rawset(it, "expired", false) end
                end
                _fix(existing)
                if sys.HeadportraitList[k] and type(sys.HeadportraitList[k]) == "table" then
                    _fix(sys.HeadportraitList[k])
                end
                if sys.HeadportraitList[id] and type(sys.HeadportraitList[id]) == "table" then
                    _fix(sys.HeadportraitList[id])
                end
                INJ_A[k] = true
                INJ_A[id] = true
            end
        end
    end

    -- ============ 把头像框 ID 合并进头像框列表 ============
    local function mergeFrames(sys)
        sys.AvatarFrameList = sys.AvatarFrameList or {}

        local function makePermanent(template)
            local item = {}
            if type(template) == "table" then
                for kk, vv in pairs(template) do
                    item[kk] = vv
                end
            else
                item = {
                    rank = 0, rank_id = 0, nation = "",
                }
            end
            rawset(item, "state",          1)
            rawset(item, "valid_hours",    0)
            rawset(item, "expire_time",    FOREVER_TS)
            rawset(item, "expire_ts",      FOREVER_TS)
            rawset(item, "expire_at",      FOREVER_TS)
            rawset(item, "expired_at",     FOREVER_TS)
            rawset(item, "receive_time",   os.time())
            rawset(item, "have_used",      1)
            rawset(item, "is_expired",     0)
            rawset(item, "expired",        false)
            return item
        end

        local template = nil
        for _, v in pairs(sys.AvatarFrameList) do
            if type(v) == "table" then
                local st = tonumber(v.state) or 0
                local vh = tonumber(v.valid_hours)
                if st > 0 and vh == 0 then
                    template = v
                    break
                end
            end
        end

        for _, id in ipairs(FRAME_IDS) do
            local existing = sys.AvatarFrameList[id] or sys.AvatarFrameList[tostring(id)]
            if existing == nil then
                sys.AvatarFrameList[id] = makePermanent(template)
                INJ_F[id] = true
            elseif type(existing) == "table" then
                local function _fix(it)
                    if tonumber(it.state) ~= 1 then rawset(it, "state", 1) end
                    if tonumber(it.valid_hours or 0) ~= 0 then rawset(it, "valid_hours", 0) end
                    if tonumber(it.expire_time or 0) < FOREVER_TS then rawset(it, "expire_time", FOREVER_TS) end
                    if tonumber(it.expire_ts   or 0) < FOREVER_TS then rawset(it, "expire_ts",   FOREVER_TS) end
                    if tonumber(it.expire_at   or 0) < FOREVER_TS then rawset(it, "expire_at",   FOREVER_TS) end
                    if tonumber(it.expired_at  or 0) < FOREVER_TS then rawset(it, "expired_at",  FOREVER_TS) end
                    if tonumber(it.is_expired  or 0) ~= 0 then rawset(it, "is_expired", 0) end
                    if it.expired == true then rawset(it, "expired", false) end
                end
                _fix(existing)
                if sys.AvatarFrameList[id] and type(sys.AvatarFrameList[id]) == "table" then
                    _fix(sys.AvatarFrameList[id])
                end
                if sys.AvatarFrameList[tostring(id)] and type(sys.AvatarFrameList[tostring(id)]) == "table" then
                    _fix(sys.AvatarFrameList[tostring(id)])
                end
                INJ_F[id] = true
            end
        end
    end

    -- ============ 通用参数整理（兼容 self 有无两种调用） ============
    local function unpackCall(...)
        local n = select("#", ...)
        if n >= 4 then
            local a1, a2, a3, a4 = ...
            return a1, a2, a3, a4
        elseif n == 3 then
            local a1, a2, a3 = ...
            if type(a1) == "table" then
                return a1, a2, a3, nil
            else
                return nil, a1, a2, a3
            end
        elseif n == 2 then
            local a1, a2 = ...
            if type(a1) == "table" then
                return a1, a2, nil, nil
            else
                return nil, a1, a2, nil
            end
        else
            local a1 = ...
            if type(a1) == "table" then
                return a1, nil, nil, nil
            else
                return nil, a1, nil, nil
            end
        end
    end

    -- ★ 修复：统一解析"第一个真实参数"，兼容 self / 无 self 两种调用
    local function pickFirstArg(self, arg1)
        if type(self) == "table" then
            return arg1
        end
        return self or arg1
    end

    -- ============ Hook 头像模块 ============
    local function hookAvatar()
        local ok, sys = pcall(require, "client.slua.logic.roleInfo.logic_roleInfo_Avatar")
        if not ok or type(sys) ~= "table" then
            print("[Beysa] 头像模块未加载")
            return false
        end

        if not sys.__orig_send_change_user_avatar then
            sys.__orig_send_change_user_avatar = sys.send_change_user_avatar
        end

        sys.send_change_user_avatar = function(...)
            local self, arg1 = unpackCall(...)
            local item_url = pickFirstArg(self, arg1)
            local id = tonumber(item_url)

            if id then
                -- ① 本地强制生效（先写独立变量）
                BF.SetAvatar(id)
                pcall(function()
                    if DataMgr then DataMgr.UpdateHeadIconUrl(tostring(id)) end
                end)

                -- ② 伪造服务器成功的回包（点号调用！绝不能改冒号）
                if type(sys.on_change_user_avatar_rsp) == "function" then
                    pcall(sys.on_change_user_avatar_rsp, 0, tostring(id))
                end

                -- ③ 发送刷新事件
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_USE_AVATAR")
                post("EVENTTYPE_LOBBY",     "EVENTID_UPDATE_LOBBY_AVATAR")
                pcall(function() if ShowNotice then ShowNotice("已应用该涂装") end end)
                print("[Beysa] 头像本地生效(伪造回包): " .. tostring(id))

                return
            end

            if type(sys.__orig_send_change_user_avatar) == "function" then
                return sys.__orig_send_change_user_avatar(...)
            end
        end

        local origRsp = sys.get_user_avatar_list_rsp
        sys.get_user_avatar_list_rsp = function(...)
            local self, err, list, url = unpackCall(...)
            if type(origRsp) == "function" then pcall(origRsp, ...) end
            if err == 0 then
                mergeAvatars(sys)
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_HEAD_INFO",
                     DataMgr and DataMgr.roleData and DataMgr.roleData.headIconUrl)
            end
        end

        mergeAvatars(sys)
        print("[Beysa] 头像 hook 挂载成功")
        return true
    end

    -- ============ Hook 头像框模块 ============
    local function hookFrame()
        local ok, sys = pcall(require, "client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
        if not ok or type(sys) ~= "table" then
            print("[Beysa] 头像框模块未加载")
            return false
        end

        if not sys.__orig_change_avatar_box then
            sys.__orig_change_avatar_box = sys.change_avatar_box
        end

        sys.change_avatar_box = function(...)
            local self, arg1 = unpackCall(...)
            local item_id = pickFirstArg(self, arg1)
            local id = tonumber(item_id)

            if id then
                -- ① 本地强制生效（先写独立变量）
                BF.SetAvatarBox(id)
                pcall(function()
                    if DataMgr and DataMgr.roleData then
                        DataMgr.roleData.cur_avatar_box_id = id
                    end
                end)
                pcall(function() sys.UpdateCurAvatarBoxID(id) end)

                -- ② 伪造服务器成功的回包（点号调用！绝不能改冒号）
                if type(sys.on_change_avatar_box_rsp) == "function" then
                    pcall(sys.on_change_avatar_box_rsp, 0, id)
                end

                -- ③ 发送刷新事件
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO")
                post("EVENTTYPE_LOBBY",     "EVENTID_UPDATE_LOBBY_AVATAR")
                pcall(function() if ShowNotice then ShowNotice("已应用该涂装") end end)
                print("[Beysa] 头像框本地生效(伪造回包): " .. tostring(id))

                return
            end

            if type(sys.__orig_change_avatar_box) == "function" then
                return sys.__orig_change_avatar_box(...)
            end
        end

        local origRsp = sys.get_avatar_box_list_rsp
        sys.get_avatar_box_list_rsp = function(...)
            local self, err, list, cur = unpackCall(...)
            if type(origRsp) == "function" then pcall(origRsp, ...) end
            if err == 0 then
                mergeFrames(sys)
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO")
            end
        end

        mergeFrames(sys)
        print("[Beysa] 头像框 hook 挂载成功")
        return true
    end

    -- ★★★ 终极保险：拦截底层提示框，强制吃掉"限时物品已过期" ★★★
    local function blockExpirePopup()
        pcall(function()
            local MsgBox = require("client.slua.logic.common.logic_common_msg_box")
            if not MsgBox or not MsgBox.Show or MsgBox.__beysa_hooked then return end
            MsgBox.__beysa_hooked = true

            local origShow = MsgBox.Show
            MsgBox.Show = function(...)
                local n = select("#", ...)
                local a = { ... }
                local content = nil
                if n >= 4 and type(a[1]) == "table" then
                    content = a[4]
                elseif n == 3 then
                    content = a[3]
                elseif n == 2 and type(a[1]) == "table" then
                    content = a[2]
                end

                if content then
                    local cStr = tostring(content)
                    if cStr:find("限时物品已过期") or cStr:find("已过期") or cStr:find("过期") then
                        print("[Beysa] 成功拦截底层过期弹窗！")
                        return
                    end
                end
                return origShow(...)
            end
        end)
    end

    -- ★★★ 新增：Hook 通用的过期检查函数（双保险）★★★
    local function hookExpireCheck()
        if _G.__beysa_expire_hooked then return end
        _G.__beysa_expire_hooked = true

        pcall(function()
            local BU = import("BackpackUtils")
            if BU and type(BU.IsBattleItemHandleExist) == "function" and not BU.__beysa_hooked then
                BU.__beysa_hooked = true
                local orig = BU.IsBattleItemHandleExist
                BU.IsBattleItemHandleExist = function(defID, ...)
                    local ok, res = pcall(orig, defID, ...)
                    if not ok or res == false then
                        local rid = defID and (defID.TypeSpecificID or defID.resID or defID)
                        rid = tonumber(rid)
                        if rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                            return true
                        end
                    end
                    return res
                end
            end
        end)

        pcall(function()
            local AU = import("AvatarUtils")
            if AU and type(AU.IsItemExpired) == "function" and not AU.__beysa_hooked then
                AU.__beysa_hooked = true
                local orig = AU.IsItemExpired
                AU.IsItemExpired = function(itemId, ...)
                    local rid = tonumber(itemId)
                    if rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                        return false
                    end
                    return orig(itemId, ...)
                end
            end
        end)

        pcall(function()
            local LIU = package.loaded["client.slua.logic.common.Logic_ItemUtils"]
            if not LIU then return end
            for _, name in ipairs({ "IsItemExpired", "IsExpired", "CheckItemExpired" }) do
                local orig = LIU[name]
                if type(orig) == "function" and not LIU["__beysa_hooked_" .. name] then
                    LIU["__beysa_hooked_" .. name] = true
                    LIU[name] = function(itemId, ...)
                        local rid = tonumber(itemId)
                        if rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                            return false
                        end
                        return orig(itemId, ...)
                    end
                end
            end
        end)

        pcall(function()
            local UBU = import("UBackpackUtils")
            if UBU and not UBU.__beysa_hooked then
                UBU.__beysa_hooked = true
                for _, name in ipairs({ "IsItemExpired", "IsExpired", "CheckItemValid" }) do
                    local orig = UBU[name]
                    if type(orig) == "function" then
                        UBU[name] = function(itemId, ...)
                            local rid = tonumber(itemId)
                            if rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                                return false
                            end
                            return orig(itemId, ...)
                        end
                    end
                end
            end
        end)
    end

    -- ★ 新增：显式强刷大厅 UI（事件之外再补一层保险）
    local function ForceRefreshLobbyUI()
        pcall(function()
            if not UIManager or not UIManager.UI_Config then return end
            local cfg = UIManager.UI_Config.Lobby_Main_UIBP
                     or (UIManager.UI_Config.Lobby and UIManager.UI_Config.Lobby.Lobby_Main_UIBP)
            if not cfg or not UIManager.GetUI then return end
            local ui = UIManager.GetUI(cfg)
            if not ui then return end
            if ui.OnRefresh   then pcall(ui.OnRefresh, ui)   end
            if ui.RefreshData then pcall(ui.RefreshData, ui) end
        end)
    end

    local function hookAll()
        pcall(hookExpireCheck)
        pcall(blockExpirePopup)
        local a = hookAvatar()
        local b = hookFrame()
        if a or b then
            local function _refresh()
                pcall(ForceRefreshLobbyUI)
            end
            if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
                _G.Mytimer_ticker.AddTimer(0.1, _refresh)
            else
                _refresh()
            end
        end
        return a and b
    end

    -- ★ 关键修复：pcall 只返回 true/false，必须同时判断"返回值"
    local _ok, _res = pcall(hookAll)
    if not _ok or not _res then
        local retryList = { 3.0, 8.0, 20.0, 40.0, 60.0 }
        for _, sec in ipairs(retryList) do
            if _G.Mytimer_ticker then
                _G.Mytimer_ticker.AddTimer(sec, function() pcall(hookAll) end)
            else
                local ok2, tk = pcall(require, "common.time_ticker")
                if ok2 and tk and tk.AddTimer then
                    tk.AddTimer(sec, function() pcall(hookAll) end)
                end
            end
        end
    end
end


-- ============================================================
-- 收藏大厅解锁 + 全部展示平台解锁
-- ============================================================

local SOCIAL_HALL_CONFIG = {
    ROOM_SCENE_NAME = "Lobby_Social_CH_Mesh",   -- 收藏大厅场景名
    CAMERA_ID       = 10151,                    -- 大厅相机 ID
    DEFAULT_SKIN_ID = 6680101,                  -- 默认人物皮肤（备用）
    DEFAULT_BG_WALL = 6680200,                  -- 默认背景墙物品 ID
    MONUMENT_ID     = 6680702,                  -- 纪念碑物品 ID（备用）
}

-- ============================================================
-- 1) 加载收藏大厅场景
-- ★ 修复④：改成异步加载（第一个参数 false），避免主线程卡死
-- ============================================================
function _G.LoadCollectionHallScene()
    pcall(function()
        if LobbySceneManager and LobbySceneManager.LoadStreamLevel then
            -- 第二个参数 true 原来是阻塞加载，改成 false 让引擎异步加载
            LobbySceneManager.LoadStreamLevel(
                false,                          -- ★ 异步，不阻塞主线程
                SOCIAL_HALL_CONFIG.ROOM_SCENE_NAME,
                SOCIAL_HALL_CONFIG.CAMERA_ID,
                "Lobby_Light"
            )
        end
    end)
end

-- ============================================================
-- 2) 设置自己身后的背景墙
-- ★ 修复③：DataMgr 判空，避免还没加载就报错
-- ============================================================
function _G.SetBehindPlayerBackground(bgItemId)
    pcall(function()
        bgItemId = bgItemId or SOCIAL_HALL_CONFIG.DEFAULT_BG_WALL

        -- ★ 新增：DataMgr 未加载时直接跳过
        if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then
            return
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager or not ModuleManager.LobbyModuleConfig then return end

        local Logic_SocialLobbyModule = ModuleManager.GetModule(
            ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
        if not Logic_SocialLobbyModule then return end

        local myUid = tonumber(DataMgr.roleData.uid)
        if not myUid then return end

        Logic_SocialLobbyModule:SetBGWallPicItemId(myUid, bgItemId)

        -- 通知 UI 刷新
        if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
            EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE)
        end
    end)
end

-- ============================================================
-- 3) 解锁所有收藏平台
-- ★ 修复①②③：三个 Hook 都改成"先保存原函数再包装"
--   · CheckSlotTypeIsUCUnlock 返回 false（表示"不需要 UC"）
--   · GetSlotIsUnlock... / GetSlotIsUnlocked... 只对自己的 UID 生效
-- ============================================================
function _G.UnlockAllCollectionPlatforms()
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager or not ModuleManager.LobbyModuleConfig then return end

        local Logic_SocialLobbyModule = ModuleManager.GetModule(
            ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
        if not Logic_SocialLobbyModule then return end

        -- 判断 UID 是不是自己（只有看自己才全解锁，看别人保持原状）
        local function isSelfUid(uid)
            if not uid or not DataMgr or not DataMgr.roleData then return false end
            return tonumber(uid) == tonumber(DataMgr.roleData.uid)
        end

        -- ====================================================
        -- ① GetSlotIsUnlockBySlotTypeAndIndex —— 判断槽位是否已解锁
        -- ★ 修复②：只对自己生效
        -- ====================================================
        if not Logic_SocialLobbyModule.__zeroKali_slotUnlockHook then
            Logic_SocialLobbyModule.__zeroKali_slotUnlockHook = true
            local orig_GetSlotIsUnlock = Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex
            Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex =
                function(self, nUId, nSlotType, nSlotIndex)
                    if isSelfUid(nUId) then
                        return true
                    end
                    if orig_GetSlotIsUnlock then
                        return orig_GetSlotIsUnlock(self, nUId, nSlotType, nSlotIndex)
                    end
                    return false
                end
        end

        -- ====================================================
        -- ② CheckSlotTypeIsUCUnlock —— 判断该槽位是否"需要 UC 解锁"
        -- ★ 修复①：原代码返回 true 是错的，这里必须返回 false
        --   false = 不需要 UC；true = 需要 UC（会显示"用 UC 解锁"）
        -- ====================================================
        if not Logic_SocialLobbyModule.__zeroKali_ucUnlockHook then
            Logic_SocialLobbyModule.__zeroKali_ucUnlockHook = true
            local orig_CheckUCUnlock = Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock
            Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock =
                function(self, nSlotType, nSlotIndex)
                    -- ★ 修复①：返回 false 表示"无需 UC"
                    return false
                end
        end

        -- ====================================================
        -- ③ GetSlotIsUnlockedByCollectHallLevel —— 判断是否因收藏等级未达标而锁
        -- ★ 修复②：只对自己生效
        -- ====================================================
        if not Logic_SocialLobbyModule.__zeroKali_levelLockHook then
            Logic_SocialLobbyModule.__zeroKali_levelLockHook = true
            local orig_GetSlotIsUnlockedByLevel =
                Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel
            Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel =
                function(self, nUId, nSlotType, nSlotIndex)
                    if isSelfUid(nUId) then
                        return true
                    end
                    if orig_GetSlotIsUnlockedByLevel then
                        return orig_GetSlotIsUnlockedByLevel(self, nUId, nSlotType, nSlotIndex)
                    end
                    return false
                end
        end

        -- ====================================================
        -- ④ 编辑管理器：标记"当前数据是最新的"
        --   （让编辑流程允许保存/应用）
        -- ====================================================
        local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(
            ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
        if Logic_SocialLobbyEditMgrModule
           and not Logic_SocialLobbyEditMgrModule.__zeroKali_latestHook then
            Logic_SocialLobbyEditMgrModule.__zeroKali_latestHook = true
            Logic_SocialLobbyEditMgrModule.GetCurIsLatestData = function() return true end
        end

        -- 通知 UI 刷新
        if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
            EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE)
        end
    end)
end

-- ============================================================
-- 4) 启动流程
-- ★ 修复③：原来 3 行直接执行，现在改成延迟 + 分步执行
--   · 等模块加载完再跑
--   · 场景加载完成后再设背景墙
-- ============================================================
local function _zeroKaliBoot()
    -- 第 1 步：加载收藏大厅场景
    pcall(_G.LoadCollectionHallScene)

    -- 第 2 步：解锁所有平台
    pcall(_G.UnlockAllCollectionPlatforms)

    -- 第 3 步：延迟 1.5 秒再设背景墙（等场景加载完）
    local function applyBgWall()
        pcall(function()
            _G.SetBehindPlayerBackground(SOCIAL_HALL_CONFIG.DEFAULT_BG_WALL)
        end)
    end

    if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
        _G.Mytimer_ticker.AddTimer(1.5, applyBgWall)
    else
        local ok, tk = pcall(require, "common.time_ticker")
        if ok and tk and tk.AddTimer then
            tk.AddTimer(1.5, applyBgWall)
        else
            applyBgWall()   -- 实在没定时器就直接执行
        end
    end
end

-- ★ 防重复执行：热更新时不要反复加载场景
if not _G.__ZERO_KALI_SOCIAL_HALL_LOADED then
    _G.__ZERO_KALI_SOCIAL_HALL_LOADED = true

    -- 优先用定时器延迟启动，等游戏模块加载完
    if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
        _G.Mytimer_ticker.AddTimer(2.0, function() pcall(_zeroKaliBoot) end)
    else
        local ok, tk = pcall(require, "common.time_ticker")
        if ok and tk and tk.AddTimer then
            tk.AddTimer(2.0, function() pcall(_zeroKaliBoot) end)
        else
            pcall(_zeroKaliBoot)
        end
    end
end



-- ============================================================
-- v27：称号全部解锁 + 本地切换 + UI 实时刷新（纯功能版）
-- ============================================================
do
    local function getObbDir()
        if _G.GetCurrentWumingPath then
            local wp = _G.GetCurrentWumingPath()
            if wp then return wp:match("^(.*)/[^/]+$") end
        end
        local pkg = (_G.GetCurrentGamePackage and _G.GetCurrentGamePackage())
                    or "com.tencent.ig"
        return "/storage/emulated/0/Android/obb/" .. pkg
    end

    local OBB_DIR   = getObbDir()
    local TITLE_INI = OBB_DIR .. "/BeysaTitle.ini"

    local unpackFn = unpack or (table and table.unpack)
    local T = { use = 0 }
    _G.BeysaTitle = T

    local function saveT()
        pcall(function()
            local f = io.open(TITLE_INI, "w")
            if not f then return end
            f:write("[Title]\nUSE=" .. tostring(T.use) .. "\n")
            f:close()
        end)
    end

    pcall(function()
        local f = io.open(TITLE_INI, "r")
        if not f then return end
        local txt = f:read("*a"); f:close()
        T.use = tonumber(txt:match("USE%s*=%s*(%d+)")) or 0
    end)

    local function packArgs(...)
        return { n = select("#", ...), ... }
    end

    local function post(evType, evId, a1)
        pcall(function()
            if EventSystem and _G[evType] and _G[evId] then
                EventSystem:postEvent(_G[evType], _G[evId], a1)
            end
        end)
    end

    local function findTitleModule()
        local paths = {
            "client.slua.logic.roleInfo.logic_roleinfo_title",
            "client.slua.logic.roleinfo.logic_roleinfo_title",
            "client.logic.roleinfo.logic_roleinfo_title",
        }
        for _, p in ipairs(paths) do
            local ok, m = pcall(require, p)
            if ok and type(m) == "table" then return m end
        end
        return nil
    end

    -- 解锁列表里所有 state=0 的条目 + 应用本地"使用中"
    local function unlockList(list)
        if type(list) ~= "table" then return 0 end
        local unlocked = 0
        for k, v in pairs(list) do
            if type(v) == "table" then
                if v.id == nil then v.id = tonumber(k) end
                if v.expire_ts == nil then v.expire_ts = 0 end
                if v.rank == nil then v.rank = 0 end
                if v.rank_id == nil then v.rank_id = 0 end
                if v.nation == nil then v.nation = "" end
                if v.receive_time == nil then v.receive_time = os.time() end
                if v.have_used == nil then v.have_used = 1 end
                if (tonumber(v.state) or 0) == 0 then
                    v.state = 1
                    unlocked = unlocked + 1
                end
            end
        end
        if T.use ~= 0 then
            for k, v in pairs(list) do
                if type(v) == "table"
                   and tonumber(v.state) == 2
                   and tonumber(k) ~= T.use then
                    v.state = 1
                end
            end
            local e = list[T.use] or list[tostring(T.use)]
            if e then e.state = 2 end
        end
        return unlocked
    end

    -- 把 alias_list_info 同步到 aliasInfo（UI 读取这个）
    local function syncAliasInfo(S)
        if type(S.alias_list_info) ~= "table" then return 0 end
        if type(S.aliasInfo) ~= "table" then S.aliasInfo = {} end
        local cnt = 0
        for k, v in pairs(S.alias_list_info) do
            S.aliasInfo[k] = v
            cnt = cnt + 1
        end
        return cnt
    end

    -- 切换后立即刷新 UI
    local function refreshUI(S)
        syncAliasInfo(S)
        if type(S.refreshAliasList) == "function" then
            pcall(S.refreshAliasList, S)
        end
        if type(S.initAliasInfo) == "function" then
            pcall(S.initAliasInfo, S)
        end
    end

    local function hookAll()
        local S = findTitleModule()
        if not S then return false end
        if S._BeysaV27 then return true end
        if type(S.alias_list_res) ~= "function" then return false end
        S._BeysaV27 = true

        local orig = S.alias_list_res
        S.alias_list_res = function(...)
            local args = packArgs(...)
            local n = args.n
            local hasSelf = (n >= 4 and type(args[1]) == "table"
                            and type(args[2]) == "number"
                            and type(args[3]) == "table")
            local list = hasSelf and args[3] or args[2]

            if type(list) ~= "table" then
                return orig(unpackFn(args, 1, n))
            end

            unlockList(list)

            local ok = pcall(orig, unpackFn(args, 1, n))
            if ok then
                syncAliasInfo(S)
                return
            end
            return orig(unpackFn(args, 1, n))
        end

        -- 切换称号
        local origReq = S.change_alias_req
        if type(origReq) == "function" then
            S.change_alias_req = function(...)
                local a = { ... }
                local n = select("#", ...)
                local selfObj, id, state
                if n >= 3 and type(a[1]) == "table" then
                    selfObj, id, state = a[1], a[2], a[3]
                else
                    selfObj, id, state = nil, a[1], a[2]
                end

                local nid = tonumber(id)
                local list = S.alias_list_info
                local cur = type(list) == "table" and nid and (list[id] or list[nid])
                if cur then
                    if cur.state == 2 then
                        T.use = 0
                        cur.state = 1
                    else
                        T.use = nid
                    end
                    saveT()
                    pcall(unlockList, list)
                    pcall(refreshUI, S)

                    S.newCheckId = nid
                    post("EVENTTYPE_LOBBY_SOCIAL", "EVENTID_LOBBY_SOCIAL_ALIAS_LIST")
                    post("EVENTTYPE_LOBBY_SOCIAL", "EVENTID_LOBBY_SOCIAL_GOT_ALIAS_DATA")
                    pcall(function() if ShowNotice then ShowNotice(49951) end end)
                    return
                end
                if selfObj then
                    return origReq(selfObj, id, state)
                else
                    return origReq(id, state)
                end
            end
        end

        pcall(function()
            if S.get_alias_list then
                S.get_alias_list()
            end
        end)

        return true
    end

    local ok, res = pcall(hookAll)
    if not ok or not res then
        for _, sec in ipairs({ 3.0, 8.0, 20.0, 40.0 }) do
            if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
                _G.Mytimer_ticker.AddTimer(sec, function() pcall(hookAll) end)
            end
        end
    end
end


-- ============================================================
-- BEYSA RP 模块（V18.1 修复版）
-- 功能：大厅 RP 显示为已购买精英版 + 领取全部奖励
-- 放在哪里：主文件里 `_G.SkinConfigPath = "...SkinMenu.ini"` 那一行的
--          正上方（v10 资料模块之后、钱包模块之后）
-- 所需依赖：ITEMS、F、_G.BeysaWallet（V16 已有）
-- 注意：V18 文件里已有 RP 模块，不要在 V18 上重复加；
--       这个模块是加在 V16 上的。
-- 不会发送任何数据到服务器。物品会写入 BeysaWallet.ini 里的 ITEMS 列表。
-- 日志：Android/data/<包名>/files/BeysaRP.log
-- 放在 do ... end 里，避免占用主文件 200 个 local 名额
-- 作者：PatronPubgBeysa  创作者：Neysa
-- ============================================================
do
    -- ============ 基础配置 ============
    local RP_LEVEL = 100
    local AWARD_MODS = {                          -- ★ 修复：多路径兜底
        "client.slua.logic.unknow_pass.logic_unknowpass_award",
        "client.slua.logic.unknown_pass.logic_unknownpass_award",
        "client.slua.logic.unknownpass.logic_unknownpass_award",
        "client.logic.unknow_pass.logic_unknowpass_award",
    }

    -- ★ 修复：按包名定位日志路径
    local function getRpLog()
        local pkg = (_G.GetCurrentGamePackage and _G.GetCurrentGamePackage())
                    or "com.tencent.ig"
        return "/storage/emulated/0/Android/data/" .. pkg .. "/files/BeysaRP.log"
    end
    local RP_LOG = getRpLog()

    local R = { hooked = false, needParse = true, claimedAll = false, logN = 0 }
    _G.BeysaRP = R

    -- ============ 日志（最多 100 行） ============
    local function rlog(msg)
        if R.logN > 100 then return end
        R.logN = R.logN + 1
        pcall(function()
            local f = io.open(RP_LOG, "a")
            if f then
                f:write(os.date("%H:%M:%S") .. " " .. tostring(msg) .. "\n")
                f:close()
            end
        end)
    end

    -- ============ 检查 ITEMS 里是否已有这个物品 ============
    -- ★ 修复：ITEMS 为 nil 时返回 true（视为"已有"，避免崩溃也避免重复添加）
    local function hasItem(id)
        if type(ITEMS) ~= "table" then return true end
        for _, v in ipairs(ITEMS) do
            if tonumber(v) == id then return true end
        end
        return false
    end

    -- ============ 发放物品（写入 ITEMS + BeysaWallet） ============
    local function giveItems(ids)
        local W = _G.BeysaWallet
        if not W then return 0 end
        if type(ITEMS) ~= "table" then return 0 end
        local added = 0
        for _, id in ipairs(ids) do
            id = tonumber(id)
            if id and id >= 100000 and not hasItem(id) then
                ITEMS[#ITEMS + 1] = id
                if type(W.items) == "table" then
                    W.items[#W.items + 1] = id
                end
                added = added + 1
            end
        end
        if added > 0 then
            pcall(W.save)
            if _G.F then
                pcall(F.injectAll)
                pcall(F.scheduleInjectRefresh)
            end
        end
        return added
    end

    -- ============ 获取奖励模块（多路径兜底） ============
    local function getAward()
        for _, path in ipairs(AWARD_MODS) do
            local ok, A = pcall(require, path)
            if ok and type(A) == "table" then
                return A, path
            end
        end
        return nil, nil
    end

    -- ============ 收集某个等级信息里的奖励 ID ============
    -- isElite: true=精英, false=普通, nil=两者都收集
    -- groupId: 指定组 ID，nil/0=不限
    local function collect(info, isElite, groupId, out)
        if type(info) ~= "table" then return end
        local lists
        if isElite == nil then
            lists = { info.OrdinaryAwardList, info.EliteAwardList }
        elseif isElite then
            lists = { info.EliteAwardList }
        else
            lists = { info.OrdinaryAwardList }
        end
        for _, lst in ipairs(lists) do
            if type(lst) == "table" then
                for _, it in pairs(lst) do
                    if type(it) == "table" then
                        -- ★ 修复：字段名多路兜底
                        local rid = it.resId or it.resid or it.res_id
                        if rid then
                            local okGroup = (groupId == nil or groupId == 0)
                                          or (it.groupId == nil)
                                          or (it.groupId == groupId)
                            if okGroup then
                                out[#out + 1] = rid
                            end
                        end
                    end
                end
            end
        end
    end

    -- ============ 把 ID 列表转成协议需要的奖励列表结构 ============
    local function toRewardList(ids)
        local rl = {}
        for _, id in ipairs(ids) do
            -- 同时提供 resid / res_id / resId / count / num / number，
            -- 不同版本协议读的字段名不一样，写全了都能命中
            rl[#rl + 1] = {
                resid = id, res_id = id, resId = id,
                count = 1, num = 1, number = 1,
            }
        end
        return rl
    end

    -- ============ 调用 on_xxx_rsp（兼容 method / 静态两种） ============
    -- ★ 修复：参数错位
    local function callRsp(UH, name, ...)
        local fn = UH[name]
        if type(fn) ~= "function" then return false end
        local args = { n = select("#", ...), ... }
        -- 先试 method
        local ok1 = pcall(fn, UH, table.unpack and table.unpack(args, 1, args.n)
                                       or unpack(args, 1, args.n))
        if ok1 then return true end
        -- 再试静态
        local ok2 = pcall(fn, table.unpack and table.unpack(args, 1, args.n)
                             or unpack(args, 1, args.n))
        return ok2
    end

    -- ============ 领取全部奖励 ============
    function R.claimAll()
        local A = getAward()
        local list = A and A.AwardLevelList
        if type(list) ~= "table" then return false end
        local ids = {}
        for _, info in ipairs(list) do
            collect(info, nil, nil, ids)
        end
        local n = giveItems(ids)
        rlog("全部奖励: 总计=" .. #ids .. " 新增=" .. n)
        R.claimedAll = true
        return true
    end

    -- ============ 应用 RP 状态 ============
    function R.apply()
        local S = rawget(_G, "UnknowPassSystem")
        if type(S) ~= "table" then return end

        -- ★ 修复：等级变化时清 needParse
        if S.IsBuyElite ~= true or S.Level ~= RP_LEVEL then
            R.needParse = true
        end
        S.IsBuyElite    = true
        S.IsBuyEliteSeg2 = true
        S.PassType      = 2
        S.Level         = RP_LEVEL
        if type(S.Data) == "table" and type(S.Data.base) == "table" then
            S.Data.base.cur_value = RP_LEVEL
        end

        -- 首次解析奖励数据
        if R.needParse and type(S.Data) == "table" and S.Data.base then
            local A = getAward()
            if A and A.GetAwardLevelList then
                -- ★ 修复：先试 method 后试静态
                local ok, e = pcall(A.GetAwardLevelList, A, true)
                if not ok then
                    ok, e = pcall(A.GetAwardLevelList, true)
                end
                if ok then
                    R.needParse = false
                else
                    rlog("解析失败: " .. tostring(e))
                end
            end
        end

        if not R.claimedAll then
            R.claimAll()
        end
    end

    -- ============ 安装 Hook ============
    function R.installHook()
        if R.hooked then return end
        local ok, UH = pcall(require, "client.network.Protocol.UpassHandle")
        if not ok or type(UH) ~= "table"
           or type(UH.send_upass_get_level_award_req) ~= "function" then
            return
        end
        R.hooked = true

        -- ---- Hook 单个领取 ----
        local origOne = UH.send_upass_get_level_award_req
        UH.send_upass_get_level_award_req = function(level, is_elite_task, group_id, is_elite_plus, ...)
            local A = getAward()
            local info = A and A.AwardLevelList and A.AwardLevelList[level]
            if not info then
                rlog("领奖: 无等级信息 level=" .. tostring(level) .. " → 走游戏原逻辑")
                return origOne(level, is_elite_task, group_id, is_elite_plus, ...)
            end

            -- ★ 修复：先按 group 收集
            local ids = {}
            collect(info, is_elite_task and true or false, group_id, ids)

            -- ★ 修复：elite+ 时不再二次收集（避免重复）
            -- 如果 group_id 为 nil/0 且是 elite+，就一次性收集所有精英奖励
            if is_elite_task and is_elite_plus and (group_id == nil or group_id == 0) then
                ids = {}
                collect(info, true, nil, ids)
            end

            giveItems(ids)
            rlog("领奖 level=" .. tostring(level) .. " ids=" .. tostring(table.concat(ids, ",")))
            callRsp(UH, "on_upass_get_level_award_rsp",
                    0, level, is_elite_task, toRewardList(ids),
                    group_id, {}, is_elite_plus)
        end

        -- ---- Hook 批量领取 ----
        if type(UH.send_upass_batch_get_level_award_req) == "function" then
            local origBatch = UH.send_upass_batch_get_level_award_req
            UH.send_upass_batch_get_level_award_req = function(selects, ...)
                local A = getAward()
                local list = A and A.AwardLevelList
                if type(list) ~= "table" then
                    rlog("批量领奖: 无列表 → 走游戏原逻辑")
                    return origBatch(selects, ...)
                end
                local ids = {}
                for _, info in ipairs(list) do
                    collect(info, nil, nil, ids)
                end
                giveItems(ids)
                rlog("批量领奖 物品数=" .. #ids)
                callRsp(UH, "on_upass_batch_get_level_award_rsp",
                        0, toRewardList(ids), {})
            end
        end
    end

    -- ============ 主 tick ============
    function R.tick()
        if not R.hooked then pcall(R.installHook) end
        local ok, e = pcall(R.apply)
        if not ok then rlog("apply 出错: " .. tostring(e)) end
    end

    -- ============ 挂载到 BeysaWalletTick（防重复包装） ============
    -- ★ 修复：最严重的 bug —— 每次执行都会把旧 tick 再包一层，
    --   多次加载（热更新、多文件引用）后，tick 套娃越来越深，最终卡死主线程。
    --   用一个独立标志避免重复包装。
    if not _G.__BeysaRPTickInstalled then
        _G.__BeysaRPTickInstalled = true
        local oldTick = _G.BeysaWalletTick
        _G.BeysaWalletTick = function(...)
            if oldTick then pcall(oldTick, ...) end
            pcall(R.tick)
        end
    else
        -- 已经装过了，这次只更新一下 R 的引用
        if _G.BeysaRP and _G.BeysaRP.tick then
            -- 什么都不做，旧的 tick 已经会调 BeysaRP.tick
        end
    end
end


-- ============================================================
-- LuckybackHandler 最终版
-- 功能：
--   ① 单抽：从真实奖池按权重抽（点游戏按钮即可）
--   ② 再次抽奖：正常可用
--   ③ 十连：调 _G.DoLuckyTenDraw() 手动执行
-- 日志：/storage/emulated/0/Android/obb/<包名>/BeysaLuckyback.log
-- ============================================================
local function InitLuckybackFinal()
    -- ============ obb 日志 ============
    local function getObbDir()
        if _G.GetCurrentWumingPath then
            local wp = _G.GetCurrentWumingPath()
            if wp then return wp:match("^(.*)/[^/]+$") end
        end
        local pkg = (_G.GetCurrentGamePackage and _G.GetCurrentGamePackage())
                    or "com.tencent.ig"
        return "/storage/emulated/0/Android/obb/" .. pkg
    end
    local LOG_PATH = getObbDir() .. "/BeysaLuckyback.log"

    local function LOG(msg)
        pcall(function()
            local f = io.open(LOG_PATH, "a+")
            if f then
                f:write(os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
                f:close()
            end
        end)
        pcall(function() print("[Luckyback] " .. tostring(msg)) end)
    end

    LOG("")
    LOG("========== Luckyback 最终版 " ..
        os.date("%Y-%m-%d %H:%M:%S") .. " ==========")

    -- ============ 加载模块 ============
    local ok, LB = pcall(require, "client.network.Protocol.LuckybackHandler")
    if not ok or type(LB) ~= "table" then
        LOG("❌ LuckybackHandler 加载失败")
        return
    end

    -- ============ 参数解析（兼容有 self / 无 self） ============
    local function parseArgs(...)
        local args = { n = select("#", ...), ... }
        if args.n >= 1 and type(args[1]) == "table" and args[1] == LB then
            return true, args
        end
        return false, args
    end

    -- ============ 活动缓存 ============
    local activityCache = {}
    local function cacheActivity(activityId, data)
        activityId = tonumber(activityId)
        if not activityId or activityId <= 0 then return end
        if type(data) ~= "table" then return end
        activityCache[activityId] = data
        local cnt = 0
        if type(data.item_table) == "table" then
            for _ in pairs(data.item_table) do cnt = cnt + 1 end
        end
        LOG("✅ 缓存活动 " .. activityId .. "，奖池 " .. cnt .. " 个")
    end

    -- ============ 按权重抽取 ============
    local function pickByWeight(itemTable, count, useUnique)
        local items = {}
        local totalWeight = 0
        for _, v in pairs(itemTable or {}) do
            if type(v) == "table" then
                local id = tonumber(v.award_item_id)
                local w  = tonumber(v.award_weight) or 0
                if id and id > 0 and w > 0 then
                    items[#items + 1] = {
                        id    = id,
                        num   = tonumber(v.award_item_num) or 1,
                        weight = w,
                    }
                    totalWeight = totalWeight + w
                end
            end
        end
        if #items == 0 or totalWeight <= 0 then
            LOG("  ⚠ 奖池无效")
            return {}
        end

        local result = {}
        if useUnique then
            -- 洗牌取前 count（十连不重复）
            for i = #items, 2, -1 do
                local j = math.random(i)
                items[i], items[j] = items[j], items[i]
            end
            for i = 1, math.min(count, #items) do
                result[#result + 1] = items[i]
            end
        else
            -- 按权重随机（单抽）
            for i = 1, count do
                local r = math.random() * totalWeight
                local acc = 0
                for _, item in ipairs(items) do
                    acc = acc + item.weight
                    if r <= acc then
                        result[#result + 1] = item
                        break
                    end
                end
            end
        end

        local ids = {}
        for _, item in ipairs(result) do
            ids[#ids + 1] = tostring(item.id) .. "x" .. tostring(item.num)
        end
        LOG("  抽到: " .. table.concat(ids, ","))
        return result
    end

    -- ============ 构造奖励列表 ============
    local function toRewards(picked)
        local rl = {}
        for i, item in ipairs(picked) do
            rl[i] = {
                resid = item.id, res_id = item.id, count = item.num or 1,
                valid_hours = 0, is_luck = (i == 1), order = i,
                drop_fun = 0, must_reward = (i == 1) and 1 or 0,
                to_res_id = 0, to_res_cnt = 0,
            }
        end
        return rl
    end

    -- ============ 加到仓库 ============
    local function addToInventory(picked)
        pcall(function()
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local center = require("client.slua.logic.wardrobe.logic_wardrobe_data_center")
            local de = center.GetWardrobeData()
            if not de then return end
            local changes = {}
            for _, item in ipairs(picked) do
                if not de:GetDataByResID(item.id, false) then
                    local instid = tonumber(os.time()) * 1000 + math.random(1, 999)
                    changes[instid] = {
                        instid = instid, res_id = item.id, count = item.num or 1,
                        isnew = 1, valid_hours = 0, expire_ts = 0,
                        lock_cnt = 0, source = 0,
                    }
                end
            end
            if next(changes) then wd:OnHallDepotDataNotify(changes) end
        end)
    end

    -- ============ 显示奖励面板 ============
    local function showPanel(picked, isTen)
        pcall(function()
            local rl = toRewards(picked)
            local cfg = UIManager and UIManager.UI_Config
                        and UIManager.UI_Config.new_supply_get_panel
            if not cfg then return end
            if UIManager.IsUIShow and UIManager.IsUIShow(cfg) then
                local ui = UIManager.GetUI(cfg)
                if ui and ui.TryShowSupplyGetPanel then
                    ui:TryShowSupplyGetPanel(rl, isTen, {needShowMovie = true})
                end
            else
                UIManager.ShowUI(cfg, rl, isTen, {needShowMovie = true})
            end
        end)
    end

    -- ============ Hook 活动数据响应（缓存奖池） ============
    if type(LB.on_get_lucky_draw_back_activity_rsp) == "function"
       and not LB.__final_cache then
        LB.__final_cache = true
        local orig = LB.on_get_lucky_draw_back_activity_rsp
        LB.__orig_rsp = orig

        LB.on_get_lucky_draw_back_activity_rsp = function(...)
            local hasSelf, args = parseArgs(...)
            local errCode, activityData, playerState
            if hasSelf then
                errCode      = args[2]
                activityData = args[3]
                playerState  = args[4]
            else
                errCode      = args[1]
                activityData = args[2]
                playerState  = args[3]
            end

            if errCode == 0 and type(playerState) == "table" then
                local aid = tonumber(playerState.activity_id)
                if aid then cacheActivity(aid, activityData) end
            end
            return orig(...)
        end
        LOG("✅ hook 活动数据响应")
    end

    -- ============ Hook 单抽（从真实奖池抽 + 调 rsp） ============
    if type(LB.send_do_one_draw_back_by_activity_req) == "function"
       and not LB.__final_draw then
        LB.__final_draw = true
        local orig = LB.send_do_one_draw_back_by_activity_req
        LB.__orig_draw = orig

        LB.send_do_one_draw_back_by_activity_req = function(...)
            local hasSelf, args = parseArgs(...)
            local activityId, drawParam
            if hasSelf then
                activityId = args[2]; drawParam = args[3]
            else
                activityId = args[1]; drawParam = args[2]
            end

            LOG("★ 单抽: activityId=" .. tostring(activityId) ..
                " param=" .. tostring(drawParam))

            local cache = activityCache[tonumber(activityId) or 0]
            if not cache or type(cache.item_table) ~= "table" then
                LOG("  ⚠ 无缓存 → 走原逻辑")
                return orig(...)
            end

            local picked = pickByWeight(cache.item_table, 1, false)
            if #picked == 0 then return orig(...) end

            addToInventory(picked)
            showPanel(picked, false)

            -- 调 rsp 让"再次抽奖"按钮可用
            local rspFn = LB.on_do_one_draw_back_by_activity_rsp
            if type(rspFn) == "function" then
                local rewards = toRewards(picked)
                local okR = pcall(rspFn, LB, 0, activityId, rewards, drawParam)
                if okR then
                    LOG("  ✅ rsp 回调成功")
                end
            end

            LOG("  ✅ 单抽完成")
            return
        end
        LOG("✅ hook 单抽")
    end

    -- ============ 全局函数：手动十连 ============
    _G.DoLuckyTenDraw = function(activityId)
        activityId = tonumber(activityId)
        if not activityId or activityId <= 0 then
            -- 自动选第一个缓存的活动
            for aid in pairs(activityCache) do
                activityId = aid
                break
            end
        end
        if not activityId then
            LOG("⚠ DoLuckyTenDraw: 无缓存活动，请先打开一次抽奖界面")
            return false
        end

        LOG("★★ 十连: activityId=" .. activityId)
        local cache = activityCache[activityId]
        if not cache or type(cache.item_table) ~= "table" then
            LOG("  ⚠ 无缓存奖池")
            return false
        end

        local picked = pickByWeight(cache.item_table, 10, true)
        if #picked == 0 then return false end

        addToInventory(picked)
        showPanel(picked, true)

        -- 调 rsp 让 UI 状态更新
        local rspFn = LB.on_do_one_draw_back_by_activity_rsp
        if type(rspFn) == "function" then
            pcall(rspFn, LB, 0, activityId, toRewards(picked), 10)
        end

        LOG("  ✅ 十连完成（" .. #picked .. " 个物品）")
        return true
    end

    LOG("========== 加载完成 ==========")
    LOG("【使用】单抽：点游戏单抽按钮")
    LOG("【使用】十连：调 _G.DoLuckyTenDraw()")
end


pcall(InitLuckybackFinal)

pcall(function()
    math.randomseed(os.time() + math.floor(math.clock and math.clock() * 100000 or 0))
end)


-- ============================================================
-- ProfileBeautify - 个人主页美化（旧版实现）
-- 需要 FeatureSwitch 配置项：PROFILE_BG、PROFILE_CARD、CI_GOLD_NAME
-- ============================================================
_G.ProfileBeautify = _G.ProfileBeautify or {}
do
    -- 以下 ID 可直接修改为想要的资源 ID
    local SELF_BG_ID    = 61510029   -- 个人主页背景
    local SELF_CARTE_ID = 61100155   -- 社交名片框
    local GOLD_PLAN_ID  = 61910003   -- 金色昵称
    local AVATAR_FRAME_ID = 0  -- 头像框
    local AVATAR_ID       = 0        -- 头像（0=不替换）

    local SWAP_LIST = {
        [61510000] = 61510006,
        [61100001] = 61100044,
        [61300001] = 61300046,
        [61910002] = 61910003,
    }

    local function isSelfUid(uid)
        local l = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
        return l and tostring(uid) == tostring(l)
    end

    local function getTicker()
        return _G.Mytimer_ticker or _G.timer_ticker
    end

    -- 1) 资源ID替换表
    do
        local installed = false
        local function install()
            if installed then return true end
            if type(CDataTable) ~= "table" or type(CDataTable.GetTableData) ~= "function" then return false end
            local orig = CDataTable.GetTableData
            CDataTable.GetTableData = function(tblName, id, ...)
                local swapTo = SWAP_LIST[tonumber(id)]
                if swapTo then
                    local ok, cfg = pcall(orig, tblName, swapTo, ...)
                    if ok and cfg then return cfg end
                end
                return orig(tblName, id, ...)
            end
            installed = true
            return true
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 2) 主页背景
    do
        local installed = false
        local function install()
            if installed then return true end
            if not (ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig) then return false end
            local ok, m = pcall(ModuleManager.GetModule, ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
            if not ok or type(m) ~= "table" then return false end
            if type(m.GetSelfRoleInfoBGID) == "function" and not m.__bgHooked then
                m.GetSelfRoleInfoBGID = function() return SELF_BG_ID end
                m.__bgHooked = true
            end
            if type(m.GetPlayerRoleInfoBGID) == "function" and not m.__bgHooked2 then
                local orig = m.GetPlayerRoleInfoBGID
                m.GetPlayerRoleInfoBGID = function(self, uid, ...)
                    if isSelfUid(uid) then return SELF_BG_ID end
                    return orig(self, uid, ...)
                end
                m.__bgHooked2 = true
            end
            installed = m.__bgHooked == true
            return installed
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 3) 社交名片框
    do
        local installed = false
        local function install()
            if installed then return true end
            local ok, sc = pcall(require, "client.slua.logic.lobby.Left.logic_social_card")
            if not ok or type(sc) ~= "table" or type(sc.GetCarteFrameEquipIdByProfile) ~= "function" then return false end
            if sc.__carteHooked then installed = true; return true end
            local orig = sc.GetCarteFrameEquipIdByProfile
            sc.GetCarteFrameEquipIdByProfile = function(profile, ...)
                if profile and type(profile) == "table" and isSelfUid(profile.uid) then
                    return SELF_CARTE_ID
                end
                return orig(profile, ...)
            end
            sc.__carteHooked = true
            installed = true
            return true
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 4) 金色昵称
    do
        local installed = false
        local function install()
            if installed then return true end
            if not (ModuleManager and ModuleManager.GetModule and ModuleManager.CommonModuleConfig) then return false end
            local ok, mgr = pcall(ModuleManager.GetModule, ModuleManager.CommonModuleConfig.NicknameColorManager)
            if not ok or type(mgr) ~= "table" or type(mgr.GetUserData) ~= "function" then return false end
            if mgr.__goldNameHooked then installed = true; return true end
            local orig = mgr.GetUserData
            mgr.GetUserData = function(self, UID)
                if isSelfUid(UID) then return GOLD_PLAN_ID end
                return orig(self, UID)
            end
            mgr.__goldNameHooked = true
            installed = true
            return true
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 5) 头像框 + 头像
    do
        local function applyAvatar()
            if not (DataMgr and DataMgr.roleData) then return end
            local rd = DataMgr.roleData
            local changed = false
            if AVATAR_FRAME_ID > 0 then
                local cur = tonumber(rd.cur_avatar_box_id) or 0
                if cur ~= AVATAR_FRAME_ID then
                    local ok = pcall(function() DataMgr.UpdateAvatarBoxId(AVATAR_FRAME_ID) end)
                    if not ok then pcall(function() rd.cur_avatar_box_id = AVATAR_FRAME_ID end) end
                    changed = true
                end
                pcall(function()
                    local af = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
                    if af then
                        af.AvatarFrameList = af.AvatarFrameList or {}
                        af.AvatarFrameList[AVATAR_FRAME_ID] = af.AvatarFrameList[AVATAR_FRAME_ID] or { expire_time = 1 }
                        af.AvatarFrameList[AVATAR_FRAME_ID].expire_time = 1
                        af.HasGet = true
                        af._hasGotData = true
                    end
                end)
            end
            if AVATAR_ID > 0 then
                local want = tostring(AVATAR_ID)
                if tostring(rd.headIconUrl) ~= want then
                    local ok = pcall(function() DataMgr.UpdateHeadIconUrl(want) end)
                    if not ok then pcall(function() rd.headIconUrl = want end) end
                    changed = true
                    pcall(function()
                        local big = require("client.slua.logic.roleInfo.logic_roleInfo_BigAvatar")
                        if big and big.RefreshBigImage then big.RefreshBigImage(want) end
                    end)
                end
                pcall(function()
                    local av = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
                    if av then
                        av.HeadportraitList = av.HeadportraitList or {}
                        if av.HeadportraitList[want] == nil then av.HeadportraitList[want] = 1 end
                    end
                end)
            end
            if changed then
                pcall(function()
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO)
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_HEAD_INFO, DataMgr.roleData.headIconUrl)
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_USE_AVATAR)
                    EventSystem:postEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR)
                    EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_UPDATE_HEAD_ICON)
                end)
            end
        end
        local ticker = getTicker()
        if not (ticker and ticker.AddTimerLoop) then
            pcall(function() ticker = require("common.time_ticker") end)
        end
        if ticker and ticker.AddTimerLoop then
            pcall(applyAvatar)
            ticker.AddTimerLoop(0.5, function()
                local okF, inFight = pcall(function()
                    return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
                end)
                if okF and inFight then return end
                pcall(applyAvatar)
            end, -1, 1)
        end
    end
end


-- ============================================================
-- SocialStatsSpoof —— 个人社交数据伪造（4 合 1）
--   ① 信誉分   ② 点赞数   ③ 人气值   ④ 武器战力
--
-- 配置键（通过 UltimateEngine_Config.Set 设置，值>0 时生效）：
--   CI_CREDIT_SCORE    信誉分
--   CI_LIKE_COUNT      收藏页点赞数
--   CI_POPULARITY      个人空间人气值
--   CI_WEAPON_POWER    武器战力
--
-- 使用：
--   UltimateEngine_Config.Set("CI_CREDIT_SCORE", 1000)
--   UltimateEngine_Config.Set("CI_LIKE_COUNT", 999999)
--   UltimateEngine_Config.Set("CI_POPULARITY", 999999)
--   UltimateEngine_Config.Set("CI_WEAPON_POWER", 99999)
--   SocialStatsSpoof.Apply()
-- ============================================================
_G.SocialStatsSpoof = _G.SocialStatsSpoof or {}
do
    local M = _G.SocialStatsSpoof

    -- ============================================================
    -- 内部工具
    -- ============================================================
    local function GetTicker()
        return _G.Mytimer_ticker or _G.timer_ticker
    end

    -- 读取配置数值（返回 0 表示不生效）
    local function CfgNum(key, def)
        local ok, v = pcall(function()
            if _G.UltimateEngine_Config and _G.UltimateEngine_Config.Get then
                return _G.UltimateEngine_Config.Get(key, def or 0)
            end
        end)
        if ok then return tonumber(v) or (def or 0) end
        return def or 0
    end
    M.CfgNum = CfgNum

    -- 判断是否为自己
    local function IsSelfUid(uid)
        local u = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
        if not u then
            local ok, ret = pcall(function()
                if TeamUpNewSystem and TeamUpNewSystem.GetSelfUID then
                    return tonumber(TeamUpNewSystem.GetSelfUID())
                end
            end)
            if ok then u = ret end
        end
        return u and tostring(uid) == tostring(u)
    end
    M.IsSelfUid = IsSelfUid

    -- 安装钩子（安装失败会周期重试）
    local function Install(tag, installFn)
        local installed = false
        local function try()
            if installed then return true end
            local ok, ret = pcall(installFn)
            if ok and ret then installed = true end
            return installed
        end
        if not try() then
            local ticker = GetTicker()
            if not (ticker and ticker.AddTimerLoop) then
                pcall(function() ticker = require("common.time_ticker") end)
            end
            if ticker and ticker.AddTimerLoop then
                ticker.AddTimerLoop(3, function()
                    local okF, inFight = pcall(function()
                        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
                    end)
                    if okF and inFight then return end
                    try()
                end, 100, 1)
            end
        end
        return installed
    end

    -- ============================================================
    -- ① 信誉分伪造
    -- 模块：client.slua.logic.ReputationSystem.logic_reputation_system
    -- 钩子：GetCreditScore
    -- ============================================================
    local function InstallCredit()
        local ok, m = pcall(require, "client.slua.logic.ReputationSystem.logic_reputation_system")
        if not ok or type(m) ~= "table" or type(m.GetCreditScore) ~= "function" then
            return false
        end
        if m.__ciCreditHooked then return true end

        local orig = m.GetCreditScore
        m.GetCreditScore = function(self, ...)
            local v = CfgNum("CI_CREDIT_SCORE", 0)
            if v > 0 then return v end
            return orig(self, ...)
        end
        m.__ciCreditHooked = true
        return true
    end
    Install("ci_credit", InstallCredit)

    -- ============================================================
    -- ② 点赞数伪造
    -- 模块：LobbyModuleConfig.collect_module
    -- 钩子：GetLikeCount
    -- ============================================================
    local function InstallLikeCount()
        if not (ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig) then
            return false
        end
        local ok, m = pcall(ModuleManager.GetModule, ModuleManager.LobbyModuleConfig.collect_module)
        if not ok or type(m) ~= "table" or type(m.GetLikeCount) ~= "function" then
            return false
        end
        if m.__ciLikeHooked then return true end

        local orig = m.GetLikeCount
        m.GetLikeCount = function(self, ...)
            local v = CfgNum("CI_LIKE_COUNT", 0)
            if v > 0 then return v end
            return orig(self, ...)
        end
        m.__ciLikeHooked = true
        return true
    end
    Install("ci_likeCount", InstallLikeCount)

    -- ============================================================
    -- ③ 人气值伪造
    -- 模块：client.slua.logic.person_space.logic_roleinfo_popularity
    -- 钩子：get_popularity_rsp（回包时替换 total_devote）
    -- ============================================================
    local function InstallPopularity()
        local ok, m = pcall(require, "client.slua.logic.person_space.logic_roleinfo_popularity")
        if not ok or type(m) ~= "table" or type(m.get_popularity_rsp) ~= "function" then
            return false
        end
        if m.__ciPopHooked then return true end

        local orig = m.get_popularity_rsp
        m.get_popularity_rsp = function(ok2, uid, total_devote, ...)
            local v = CfgNum("CI_POPULARITY", 0)
            if v > 0 and IsSelfUid(uid) then
                total_devote = v
            end
            return orig(ok2, uid, total_devote, ...)
        end
        m.__ciPopHooked = true
        return true
    end
    Install("ci_popularity", InstallPopularity)

    -- ============================================================
    -- ④ 武器战力伪造
    -- 模块：client.slua.logic.weapon_strength.logic_weapon_strength
    -- 钩子：proc_get_weapon_power_data_rsp
    -- 替换字段：power_count / power / max_power
    -- ============================================================
    local function InstallWeaponPower()
        local ok, m = pcall(require, "client.slua.logic.weapon_strength.logic_weapon_strength")
        if not ok or type(m) ~= "table" or type(m.proc_get_weapon_power_data_rsp) ~= "function" then
            return false
        end
        if m.__ciWpHooked then return true end

        local orig = m.proc_get_weapon_power_data_rsp
        m.proc_get_weapon_power_data_rsp = function(self, cur, history, ...)
            local v = CfgNum("CI_WEAPON_POWER", 0)
            if v > 0 then
                local function rewrite(tbl)
                    if type(tbl) ~= "table" then return end
                    for _, e in pairs(tbl) do
                        if type(e) == "table" then
                            if tonumber(e.power_count) then e.power_count = v end
                            if tonumber(e.power)       then e.power = v end
                            if tonumber(e.max_power)   then e.max_power = v end
                        end
                    end
                end
                pcall(rewrite, cur)
                pcall(rewrite, history)
            end
            return orig(self, cur, history, ...)
        end
        m.__ciWpHooked = true
        return true
    end
    Install("ci_weaponPower", InstallWeaponPower)

    -- ============================================================
    -- 对外统一接口
    -- ============================================================
    function M.Apply()
        pcall(InstallCredit)
        pcall(InstallLikeCount)
        pcall(InstallPopularity)
        pcall(InstallWeaponPower)
    end

    function M.SetCreditScore(n)  _G.UltimateEngine_Config.Set("CI_CREDIT_SCORE", n);  pcall(InstallCredit);       end
    function M.SetLikeCount(n)    _G.UltimateEngine_Config.Set("CI_LIKE_COUNT", n);    pcall(InstallLikeCount);    end
    function M.SetPopularity(n)   _G.UltimateEngine_Config.Set("CI_POPULARITY", n);    pcall(InstallPopularity);   end
    function M.SetWeaponPower(n)  _G.UltimateEngine_Config.Set("CI_WEAPON_POWER", n);  pcall(InstallWeaponPower);  end

    -- 模块加载后立即尝试一次
    pcall(M.Apply)
end



local function InitFakeEconomyAndCrates()

    local function SafeRequire(modulePath)
        local success, result = pcall(require, modulePath)
        if not success or not result then return nil end
        return result
    end

    local EventDefine = SafeRequire("client.slua.common.EventDefine") 
                     or SafeRequire("client.slua.config.event_config") 
                     or SafeRequire("client.slua.config.EventConst")
    if EventDefine and type(EventDefine) == "table" then
        for k, v in pairs(EventDefine) do
            if _G[k] == nil then _G[k] = v end
        end
    end

    local function SafePostEvent(eventType, eventId, ...)
        if EventSystem and eventType and eventId then
            pcall(EventSystem.postEvent, EventSystem, eventType, eventId, ...)
        end
    end


    local FAKE_UC_DEFAULT = 999999999
    local fakeCurrencyPath = "/sdcard/storage/emulated/0/Android/data/com.pubg.imobile/files/FakeCurrency.json"

    local function getFakeWallet()
        _G.FakeCurrency = _G.FakeCurrency or { uc = FAKE_UC_DEFAULT }
        _G.FakeCurrency.uc = tonumber(_G.FakeCurrency.uc) or FAKE_UC_DEFAULT
        if _G.FakeCurrency.uc < 0 then _G.FakeCurrency.uc = 0 end
        return _G.FakeCurrency
    end

    local function GetFakeUC()
        return getFakeWallet().uc
    end

    local function saveFakeWallet()
        pcall(function()
            local w = getFakeWallet()
            local file = io.open(fakeCurrencyPath, "w")
            if not file then return end
            local ok, jsonStr = pcall(function()
                return (_G.json and _G.json.encode(w)) or (slua.json and slua.json.encode(w))
            end)
            if ok and jsonStr then file:write(jsonStr) end
            file:close()
        end)
    end

    local function loadFakeWallet()
        pcall(function()
            local file = io.open(fakeCurrencyPath, "r")
            if not file then return end
            local content = file:read("*a")
            file:close()
            if not content or content == "" then return end
            local ok, data = pcall(function()
                return (_G.json and _G.json.decode(content)) or (slua.json and slua.json.decode(content))
            end)
            if ok and type(data) == "table" then
                _G.FakeCurrency = data
                getFakeWallet()
            end
        end)
    end


    local function RefreshFakeCurrencyUI()
        local uc = GetFakeUC()
        pcall(function()
            local dMgr = DataMgr or _G.DataMgr
            if dMgr then
                rawset(dMgr, "ticket", uc)
                rawset(dMgr, "uc", uc)
                rawset(dMgr, "UC", uc)
                rawset(dMgr, "gold", uc)
                rawset(dMgr, "diamond", uc)
                rawset(dMgr, "eternal_diamond", uc)
                rawset(dMgr, "money", uc)
                rawset(dMgr, "currency", uc)
                rawset(dMgr, "ag", uc)
                rawset(dMgr, "silver", uc)
                if dMgr.roleData then
                    rawset(dMgr.roleData, "ticket", uc)
                    rawset(dMgr.roleData, "uc", uc)
                    rawset(dMgr.roleData, "gold", uc)
                    rawset(dMgr.roleData, "diamond", uc)
                end
            end
        end)
        SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, uc)
        SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, uc)
        SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, uc)
        SafePostEvent(EVENTTYPE_ROLE, EVENTID_ROLE_DATA_UPDATE)
        SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_CURRENCY_UPDATE)
        SafePostEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_TICKET_UPDATE)
        SafePostEvent(EVENTTYPE_STORE_DATA, EVENTID_STORE_UPDATE_EXCHANGE_COIN)
    end

    local function SpendFakeUC(amount)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return true end
        local w = getFakeWallet()
        if w.uc < amount then return false end
        w.uc = w.uc - amount
        saveFakeWallet()
        RefreshFakeCurrencyUI()
        return true
    end

    local function HasEnoughUC(amount)
        amount = tonumber(amount) or 0
        if amount <= 0 then return GetFakeUC() > 0 end
        return GetFakeUC() >= amount
    end

    local function CaptureUCPrice(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            local n = tonumber(v)
            if n and n >= 1 and n <= 20000 then
                _G._lastUCCheckPrice = n
                return n
            end
        end
        return tonumber(_G._lastUCCheckPrice) or 0
    end

    local function TrySpendUC(cost)
        cost = tonumber(cost) or 0
        if cost <= 0 then cost = tonumber(_G._lastUCCheckPrice) or 0 end
        if cost <= 0 then return true end
        return SpendFakeUC(cost)
    end

    loadFakeWallet()
    saveFakeWallet()
    _G.GetFakeUC = GetFakeUC
    _G.SpendFakeUC = SpendFakeUC


    _G.ApplyAllFakeCurrencies = function(target)
        local uc = GetFakeUC()
        local function enough(a, b, ...)
            local price = tonumber(b)
            if not price or price <= 0 then
                price = CaptureUCPrice(a, b, ...)
            else
                _G._lastUCCheckPrice = price
            end
            return HasEnoughUC(price)
        end

        local dMgr = target or DataMgr or _G.DataMgr or SafeRequire("client.slua.logic.common.DataMgr") or SafeRequire("client.data.DataMgr")
        if dMgr then
            dMgr.ticket = uc
            dMgr.eternal_diamond = uc
            dMgr.home_coin = uc
            dMgr.gold = uc
            dMgr.diamond = uc
            dMgr.pp = uc
            dMgr.bp = uc
            dMgr.coupon = uc
            dMgr.voucher = uc
            dMgr.fp_token = uc
            dMgr.gold_chip = uc
            dMgr.gen_ticket = uc
            dMgr.corps_money = uc
            dMgr.smelt = uc
            dMgr.battle_coin = uc
            dMgr.uc = uc
            dMgr.UC = uc
            dMgr.money = uc
            dMgr.currency = uc
            dMgr.ag = uc
            dMgr.silver = uc

            if dMgr.roleData then
                dMgr.roleData.bgbg_vip = 1
                dMgr.roleData.level = 100
                dMgr.roleData.ticket = uc
                dMgr.roleData.gold = uc
                dMgr.roleData.diamond = uc
                dMgr.roleData.uc = uc
            end

            dMgr.GetCurrency = function(...) return GetFakeUC() end
            dMgr.GetMoney = function(...) return GetFakeUC() end
            dMgr.GetTicket = function(...) return GetFakeUC() end
            dMgr.GetUC = function(...) return GetFakeUC() end
            dMgr.GetGold = function(...) return GetFakeUC() end
            dMgr.GetDiamond = function(...) return GetFakeUC() end
            dMgr.GetMoneyByType = function(...) return GetFakeUC() end
            dMgr.CheckMoney = enough
            dMgr.CheckCurrency = enough
            dMgr.CheckTicket = enough
            dMgr.CheckUC = enough
            dMgr.CheckIsEnough = enough
            dMgr.IsMoneyEnough = enough
            dMgr.IsCurrencyEnough = enough

            if EventSystem and EVENTTYPE_DATA_MGR then
                if EVENTID_DATAMGR_GOLD_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, uc) end
                if EVENTID_DATAMGR_TICKET_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, uc) end
                if EVENTID_DATAMGR_DIAMOND_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, uc) end
            end
        end

        local role_data = SafeRequire("client.slua.logic.role.role_data") or SafeRequire("client.slua.logic.role.logic_role") or SafeRequire("client.slua.logic.role.RoleData")
        if role_data then
            role_data.ticket = uc
            role_data.uc = uc
            role_data.gold = uc
            role_data.diamond = uc
            role_data.money = uc
            role_data.currency = uc
            role_data.ag = uc
            role_data.silver = uc
            role_data.GetTicket = function(...) return GetFakeUC() end
            role_data.GetUC = function(...) return GetFakeUC() end
            role_data.GetGold = function(...) return GetFakeUC() end
            role_data.GetMoney = function(...) return GetFakeUC() end
            role_data.GetDiamond = function(...) return GetFakeUC() end
            role_data.GetCurrency = function(...) return GetFakeUC() end
        end

        pcall(function()
            local StoreUtils = SafeRequire("client.slua.logic.store.utils.store_utils")
            if StoreUtils and StoreUtils.GetMoneyInfo then
                StoreUtils.GetMoneyInfo = function()
                    local n = GetFakeUC()
                    return { nDiamond = n, nUC = n, nSilver = n, nGold = n, nTicket = n }
                end
            end
        end)

        pcall(function()
            local Logic_ItemUtils = SafeRequire("client.slua.logic.common.Logic_ItemUtils")
            if Logic_ItemUtils and Logic_ItemUtils.GetItemCount then
                local origGIC = Logic_ItemUtils.GetItemCount
                Logic_ItemUtils.GetItemCount = function(nItemId, bForever)
                    local num = tonumber(nItemId)
                    if num == 1109 or num == 1006 or num == 1001 or num == 1002 or num == 1003 then return GetFakeUC() end
                    return origGIC and origGIC(nItemId, bForever) or 0
                end
            end
        end)
    end

    -- تجاوز صناديق الدفع وشاشات الشحن
    local logic_common_pay_box = SafeRequire("client.slua.logic.common.Payclass.logic_common_pay_box")
    if logic_common_pay_box then
        logic_common_pay_box.ShowUcRechargeMsg = function() return true end
        logic_common_pay_box.ShowPayBox = function() return true end
        logic_common_pay_box.CheckIsEnoughUC = function() return true end
    end


    local _fakeInsIdCounter = 900000000
    local _loadedFakeItems = nil

    local function loadFakeItems()
        if _loadedFakeItems then return _loadedFakeItems end
        _loadedFakeItems = {}
        pcall(function()
            local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
            local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eSupplyRepeatedList)
            if data and type(data) == "table" and data.fakeItems then
                for _, resId in pairs(data.fakeItems) do
                    _loadedFakeItems[tonumber(resId)] = true
                end
            end
        end)
        return _loadedFakeItems
    end

    local function saveFakeItems()
        pcall(function()
            local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
            local items = {}
            for resId, _ in pairs(_loadedFakeItems or {}) do
                table.insert(items, resId)
            end
            PlayerPrefsSystem.SaveTableToFile_N({ fakeItems = items }, PlayerPrefsSystem.ePlayerPrefsType.eSupplyRepeatedList)
        end)
    end

    local function addItemToInventory(resId)
        pcall(function()
            local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
            local logic_wardrobe_data_center = require("client.slua.logic.wardrobe.logic_wardrobe_data_center")
            local DataEntity = logic_wardrobe_data_center.GetWardrobeData()
            if not DataEntity then return end
            if DataEntity:GetDataByResID(resId, false) then return end

            _fakeInsIdCounter = _fakeInsIdCounter + 1
            local instid = _fakeInsIdCounter

            local changeEntry = {
                instid = instid,
                res_id = resId,
                count = 1,
                isnew = 1,
                valid_hours = 0,
                expire_ts = 0,
                lock_cnt = 0,
                source = 0,
            }

            local changelist = {}
            changelist[instid] = changeEntry
            wardrobe_data:OnHallDepotDataNotify(changelist)

            _loadedFakeItems = _loadedFakeItems or {}
            _loadedFakeItems[resId] = true
            saveFakeItems()
        end)
    end

    -- استخراج محتويات البكج المفتوح حالياً من شاشة اللعبة
    local function getCrateItemsFromUI()
        local result = {}
        pcall(function()
            if UIManager and UIManager.UI_Config then
                local store_supply_switcher = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_supply_switcher)
                if store_supply_switcher then
                    local supplySystem = store_supply_switcher:GetSupplySystem()
                    if supplySystem and supplySystem.PageListPanel and supplySystem.PageListPanel.itemDataList then
                        for _, v in pairs(supplySystem.PageListPanel.itemDataList) do
                            if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                table.insert(result, tonumber(v.itemId))
                            end
                        end
                    end
                    if #result == 0 then
                        local storeSystem = store_supply_switcher:GetStoreSystem()
                        if storeSystem and storeSystem.PageListPanel and storeSystem.PageListPanel.itemDataList then
                            for _, v in pairs(storeSystem.PageListPanel.itemDataList) do
                                if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                    table.insert(result, tonumber(v.itemId))
                                end
                            end
                        end
                    end
                end
            end
        end)
        return result
    end

    local function makeFakeItemList(count)
        count = count or 1
        local list = {}
        local pool = getCrateItemsFromUI()
        if #pool == 0 and _G.ITEMS then pool = _G.ITEMS end
        if #pool == 0 then return list end

        for i = 1, count do
            local resId = pool[math.random(#pool)]
            table.insert(list, {
                resid = resId,
                res_id = resId,
                count = 1,
                valid_hours = 0,
                is_luck = (i == 1),
                order = i,
                drop_fun = 0,
                must_reward = (i == 1) and 1 or 0,
                to_res_id = 0,
                to_res_cnt = 0,
                ShowUseTime = true,
                getTags = 0,
            })
            addItemToInventory(resId)
        end
        return list
    end

    -- إظهار واجهة المكافآت مع الأنيميشن والفيديو
    local function showGetPanel(itemList, isTen)
        pcall(function()
            local rewardList = {}
            for _, v in pairs(itemList) do
                table.insert(rewardList, {
                    res_id = v.res_id or v.resid,
                    count = v.count or 1,
                    valid_hours = v.valid_hours or 0,
                    getTags = v.drop_fun or 0,
                    to_res_id = v.to_res_id or 0,
                    to_res_cnt = v.to_res_cnt or 0,
                    ShowUseTime = true,
                })
            end
            if UIManager and UIManager.UI_Config and UIManager.UI_Config.new_supply_get_panel then
                if UIManager.IsUIShow and UIManager.IsUIShow(UIManager.UI_Config.new_supply_get_panel) then
                    local boxUI = UIManager.GetUI(UIManager.UI_Config.new_supply_get_panel)
                    if boxUI and boxUI.TryShowSupplyGetPanel then
                        boxUI:TryShowSupplyGetPanel(rewardList, isTen, {needShowMovie = true})
                    end
                else
                    UIManager.ShowUI(UIManager.UI_Config.new_supply_get_panel, rewardList, isTen, {needShowMovie = true})
                end
            end
        end)
    end

    local LogicSupply = SafeRequire("client.slua.logic.supply.logic_supply")
    if LogicSupply and not LogicSupply._supplyHooked then
        LogicSupply._supplyHooked = true
        LogicSupply.IsCanBuySupplyBox = function(item_id) return true end
        LogicSupply.CheckHasSelectWish = function(tabId, boxItemId) return true end
        LogicSupply.CheckCrateLimitTime = function(boxEndTime) return false end
        LogicSupply.ShowTipsWhenHaveFreeBan = function(itemId, isOne) return false end
    end

    local StoreHandler = SafeRequire("client.network.Protocol.StoreHandler")
    if StoreHandler and not StoreHandler._crateHooked then
        StoreHandler._crateHooked = true


        StoreHandler.send_buy_shop_by_id_req = function(params)
            local isTen = false
            local shopId = 0
            if type(params) == "table" then
                shopId = tonumber(params[1]) or 0
                local buyCount = tonumber(params[8]) or 1
                if buyCount == 10 then isTen = true end
            end


            TrySpendUC(isTen and 540 or 60)

            local itemList = makeFakeItemList(isTen and 10 or 1)
            if StoreHandler.on_buy_shop_by_id_rsp then
                pcall(StoreHandler.on_buy_shop_by_id_rsp, 0, shopId, itemList)
            end
            showGetPanel(itemList, isTen)
        end
    end


    local RechargePurchaseHandler = SafeRequire("client.network.Protocol.RechargePurchaseHandler")
    if RechargePurchaseHandler then
        RechargePurchaseHandler.send_direct_buy_pre_check = function(activityId)
            if RechargePurchaseHandler.on_direct_buy_pre_check_rsp then
                RechargePurchaseHandler.on_direct_buy_pre_check_rsp(0, activityId)
            end
        end
        RechargePurchaseHandler.send_unified_purchase = function(activityId, selectedNumber, couponId)
            local amount = tonumber(selectedNumber) or 6000
            local w = getFakeWallet()
            w.uc = w.uc + amount
            saveFakeWallet()
            RefreshFakeCurrencyUI()
            if RechargePurchaseHandler.on_unified_purchase_rsp then
                RechargePurchaseHandler.on_unified_purchase_rsp(0, 1109, amount, 0)
            end
        end
    end


    if _G.ApplyAllFakeCurrencies then
        pcall(_G.ApplyAllFakeCurrencies)
    end
end


pcall(InitFakeEconomyAndCrates)


if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimerLoop then
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        if _G.ApplyAllFakeCurrencies then
            pcall(_G.ApplyAllFakeCurrencies)
        end
    end, -1, 1) -- يتكرر كل 1 ثانية
end



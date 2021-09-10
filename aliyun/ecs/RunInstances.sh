#!/usr/bin/env bash

RegionId=
ImageId=
InstanceType=
SecrurityGroupId=
InstanceName=
InternetMaxBandwidthOut=
Hostname=
InternetChargeType=
DiskSize=
DiskCategory=
KeyPairName=
Amount=
InstanceChargeType=
dryrun=0
function usage() {
    cat <<HEREDOC
    Usage $(basename $0) [Options] ...
        required arguments:
            --rid                   regionId where instances belongs to
            --image                 imageId sepcify image to run instances with
            --type                  instanceType specify cpus and mems of the instance.for example "ecs.g6.large" means 2C8G.List avaliable instance type by --InstanceFamily
            --sid                   securityGroupId. Don's specify this will list avaliable security group id
            -n                      name of Instances.[start,bit] means "bit" length of number start from "start"fro example instancename-[0,3] means instance-000,instance-001,instance-002...instance-\$Amount
            -b                      bandwidth of instances
            --key                   KeyPair specify the publickey which will be place on your instance
            -a                      amount of instances to be run
        

        optional arguments:
            --help                  display this help message and exit
            -h                      hostname,default the value of InstanceName
            --InternetChargeType    PayByBandwidth or PayByTraffic.Default PayByTraffic
            --DiskSize              G, Defalut 40G
            --DiskCategory          cloud_efficiency,cloud_dds,cloud_essd,cloud. Default cloud_efficiency
            --InstanceChargeType    PrePaid,PostPaid.Default PrePaid.
            --dryrun                debug mode
            --rids
            --types
            --family
            --familys
            --keys
            --secgroups
            --images
HEREDOC
}

function invalid() {
    echo "ERROR: Unrecognized argument $1 ">&2
    usage
    exit 1
}

function require() {
    if [ -z "$(eval echo \$$1)" ];then
        echo "ERROR: $1 required" >&2
        exit 1
    fi
}


function ParseArguments() {
    while [ $# -gt 0 ];do
        case "$1" in 
        --help)                 usage; exit ;;
        --rid)                  shift; RegionId="$1"; shift ;;
        --rids)                 shift; DescribeRegions; exit ;;
        --image)                shift; ImageId="$1"; shift ;;
        --images)               shift; require "RegionId";DescribeImages; exit ;;
        --type)                 shift; InstanceType="$1"; shift;;
        --types)                shift; DescribeInstanceTypes; exit ;;
        --secgroup)             shift; SecrurityGroupId="$1"; shift;;
        --secgroups)            shift; require "RegionId";DescribeSecurityGroups; exit;;
        -n)                     shift; InstanceName="$1"; shift;;
        -b)                     shift; OutInternetMaxBandwidthOut="$1"; shift;;
        -h)                     shift; Hostname="$1"; shift;;
        --InternetChargeType)   shift; InternetChargeType="$1"; shift;;
        --InternetChargeTypes)  shift; echo -e "PayByBandwidth按固定带宽计费\nPayByTraffic(*):按使用流量计费"; exit;;
        --DiskSize)             shift; DiskSize="$1"; shift;;
        --DiskCategory)         shift; DiskCategory="$1"; shift;;
        --DiskCategorys)        shift; echo -e "coud_efficiency(*):高效云盘\ncloud_ssd:SSD云盘\ncloud_essd:ESSD云盘\ncloud:普通云盘"; exit;;
        --key)                  shift; KeyPairName="$1"; shift;;
        --keys)                 shift; require "RegionId"; DescribeKeyPairs ; exit;;
        -a)                     shift; Amount="$1"; shift;;
        --InstanceChargeType)   shift; InstanceChargeType="$1"; shift;;
        --InstanceChargeTypes)  shift; echo -e "PrePaid:包年包月\nPostPaid(*):按量付费"; exit;;
        --family)               shift; DescribeInstanceTypes --InstanceTypeFamily "$1"; exit;;
        --familys)              shift; require "RegionId";DescribeInstanceTypeFamilies; exit;;
        --dryrun)               shift; dryrun=1;;
        -*|--*)                 invalid; exit 1;;
        --)                     break;;
        *)                      usage; exit 1;;
        esac
    done
    require "RegionId"
    require "ImageId"
    require "SecurityGroupId"
    require "InstanceName"
    require "InternetMaxBandwidth"
    require "KeyPairName"
    require "Amount"
    require "InstanceType"
    if [ -z "$Hostname" ];then
        Hostname="$InstanceName"
    fi
}

function RunInstances() {
    aliyun ecs RunInstances \
        --RegionId  "$RegionId" \
        --ImageId   "$ImageId" \
        --InstanceType "$InstanceType" \
        --SecurityGroupId "$SecurityGroupId" \
        --InstanceName  "$InstanceName" \
        --InternetMaxBandwidthOut "$InternetMaxBandwidthOut" \
        --Hostname "$Hosrname"   \
        --UniqueSuffix "true"  \
        --InternetChargeType "$InternetChargeType" \
        --SystemDisk.Size  "$DiskSize"  \
        --SystemDisk.DiskName "$DiskName" \
        --KeyPairName "$KeyPairName" \
        --Amount   "$Amount"   \
        --AutoRenew "true"    \
        --InstanceChargeType   "$InstanceChargeType" \
        $1
}

function DescribeRegions() {
    ret=$( \
        aliyun ecs DescribeRegions \
            --InstanceChargeType $InstanceChargeType \
        )
    region=$(echo "$ret"|jq -r '.Regions.Region[]|"Name:  \(.LocalName)\tID:  \(.RegionId)"')
    echo -e  "$region"
}
function DescribeImages() {
    ret=$( \
        aliyun ecs DescribeImages \
            --RegionId  "$RegionId" \
            --ImageOwnerAlias "others" \
        )
    image=$(echo "$ret"|jq -r '.Images.Image[]|"Name:  \(.ImageName)\tID:  \(.ImageId)"')
    echo -e "$image"
}
function DescribeInstanceTypeFamilies() {
    ret=$( \
        aliyun ecs DescribeInstanceTypeFamilies \
            --RegionId  "$RegionId" \
    )
    family=$(echo "$ret" | jq -r '.InstanceTypeFamilies.InstanceTypeFamily[]|"ID:  \(.InstanceTypeFamilyId)"')
    echo -e "$family"
}
function DescribeInstanceTypes() {
    ret=$( \
        aliyun ecs DescribeInstanceTypes \
        "$@" \
    )
    types=$(echo "$ret"| jq -r '.InstanceTypes.InstanceType[]|"ID: \(.InstanceTypeId) conf: \(.CpuCoreCount)H\(.MemorySize)G"')
    echo -e  "$types"
}
#function DescribeVSwitches() {}
#function DescribeSecurityGroups() {}
function DescribeKeyPairs() {
    ret=$( \
        aliyun ecs DescribeKeyPairs \
        --RegionId  "$RegionId" \
    )
    keypair=$(echo "$ret"|jq -r '.KeyPairs.KeyPair[]|"Name:  \(.KeyPairName)"')
    echo -e "$keypair"
}

ParseArguments "$@"
if [ $dryrun -eq 1];then
    RunInstances --dryrun
else
    RunInstances
fi

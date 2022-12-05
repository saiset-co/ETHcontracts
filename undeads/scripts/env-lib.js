const hre = require("hardhat");

function FromSum(Sum) {
    return FromSum18(Sum);
}
function FromSum18(Sum) {
    return hre.ethers.utils.parseUnits(String(Sum), 18);
}
function FromSum6(Sum) {
    return hre.ethers.utils.parseUnits(String(Sum), 6);
}

function ToString(BigSum) {
    return BigSum.toString();
}

function ToFloat(BigSum) {
    var Sum = hre.ethers.utils.formatUnits(BigSum, 18);
    return parseFloat(Sum);
}
function ToFloat6(BigSum) {
    return parseFloat(hre.ethers.utils.formatUnits(BigSum, 6));
}

function Right(Str, count) {
    if (Str.length > count)
        return Str.substr(Str.length - count, count);
    else
        return Str.substr(0, Str.length);
}


function Sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}


global.SaveToFile = function (filename, buf) {
    filename="./data/"+filename;
    var fs = require('fs');
    var file_handle = fs.openSync(filename, "w");
    fs.writeSync(file_handle, buf, 0, buf.length);
    fs.closeSync(file_handle);
}

global.LoadParams = function (filename,DefaultValue)
{
    var fs = require('fs');
    filename="./data/"+filename;
    try
    {
        if(fs.existsSync(filename))
        {
            
            var Str = fs.readFileSync(filename);
            if(Str.length > 0)
                return JSON.parse(Str);
        }
    }
    catch(err)
    {
        console.log("LoadParams:",err)
    }
    return DefaultValue;
}

global.SaveParams = function (filename,data)
{
    SaveToFile(filename, Buffer.from(JSON.stringify(data, "", 4)));
}


global.FromSum = FromSum18;
global.FromSum18 = FromSum18;
global.FromSum6 = FromSum6;
global.ToString = ToString;
global.ToFloat = ToFloat;
global.ToFloat6 = ToFloat6;
global.Sleep = Sleep;

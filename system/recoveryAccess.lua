local sha256hex
do
    local preproc, initH256, digestblock, str2hexa, num2s
    local function a(b,c,d,...)b=b%2^32;c=c%2^32;local e=(b%0x00000002>=0x00000001 and c%0x00000002>=0x00000001 and 0x00000001 or 0)+(b%0x00000004>=0x00000002 and c%0x00000004>=0x00000002 and 0x00000002 or 0)+(b%0x00000008>=0x00000004 and c%0x00000008>=0x00000004 and 0x00000004 or 0)+(b%0x00000010>=0x00000008 and c%0x00000010>=0x00000008 and 0x00000008 or 0)+(b%0x00000020>=0x00000010 and c%0x00000020>=0x00000010 and 0x00000010 or 0)+(b%0x00000040>=0x00000020 and c%0x00000040>=0x00000020 and 0x00000020 or 0)+(b%0x00000080>=0x00000040 and c%0x00000080>=0x00000040 and 0x00000040 or 0)+(b%0x00000100>=0x00000080 and c%0x00000100>=0x00000080 and 0x00000080 or 0)+(b%0x00000200>=0x00000100 and c%0x00000200>=0x00000100 and 0x00000100 or 0)+(b%0x00000400>=0x00000200 and c%0x00000400>=0x00000200 and 0x00000200 or 0)+(b%0x00000800>=0x00000400 and c%0x00000800>=0x00000400 and 0x00000400 or 0)+(b%0x00001000>=0x00000800 and c%0x00001000>=0x00000800 and 0x00000800 or 0)+(b%0x00002000>=0x00001000 and c%0x00002000>=0x00001000 and 0x00001000 or 0)+(b%0x00004000>=0x00002000 and c%0x00004000>=0x00002000 and 0x00002000 or 0)+(b%0x00008000>=0x00004000 and c%0x00008000>=0x00004000 and 0x00004000 or 0)+(b%0x00010000>=0x00008000 and c%0x00010000>=0x00008000 and 0x00008000 or 0)+(b%0x00020000>=0x00010000 and c%0x00020000>=0x00010000 and 0x00010000 or 0)+(b%0x00040000>=0x00020000 and c%0x00040000>=0x00020000 and 0x00020000 or 0)+(b%0x00080000>=0x00040000 and c%0x00080000>=0x00040000 and 0x00040000 or 0)+(b%0x00100000>=0x00080000 and c%0x00100000>=0x00080000 and 0x00080000 or 0)+(b%0x00200000>=0x00100000 and c%0x00200000>=0x00100000 and 0x00100000 or 0)+(b%0x00400000>=0x00200000 and c%0x00400000>=0x00200000 and 0x00200000 or 0)+(b%0x00800000>=0x00400000 and c%0x00800000>=0x00400000 and 0x00400000 or 0)+(b%0x01000000>=0x00800000 and c%0x01000000>=0x00800000 and 0x00800000 or 0)+(b%0x02000000>=0x01000000 and c%0x02000000>=0x01000000 and 0x01000000 or 0)+(b%0x04000000>=0x02000000 and c%0x04000000>=0x02000000 and 0x02000000 or 0)+(b%0x08000000>=0x04000000 and c%0x08000000>=0x04000000 and 0x04000000 or 0)+(b%0x10000000>=0x08000000 and c%0x10000000>=0x08000000 and 0x08000000 or 0)+(b%0x20000000>=0x10000000 and c%0x20000000>=0x10000000 and 0x10000000 or 0)+(b%0x40000000>=0x20000000 and c%0x40000000>=0x20000000 and 0x20000000 or 0)+(b%0x80000000>=0x40000000 and c%0x80000000>=0x40000000 and 0x40000000 or 0)+(b>=0x80000000 and c>=0x80000000 and 0x80000000 or 0)return d and a(e,d,...)or e end;local function f(b,c,d,...)local e=(b%0x00000002>=0x00000001~=(c%0x00000002>=0x00000001)and 0x00000001 or 0)+(b%0x00000004>=0x00000002~=(c%0x00000004>=0x00000002)and 0x00000002 or 0)+(b%0x00000008>=0x00000004~=(c%0x00000008>=0x00000004)and 0x00000004 or 0)+(b%0x00000010>=0x00000008~=(c%0x00000010>=0x00000008)and 0x00000008 or 0)+(b%0x00000020>=0x00000010~=(c%0x00000020>=0x00000010)and 0x00000010 or 0)+(b%0x00000040>=0x00000020~=(c%0x00000040>=0x00000020)and 0x00000020 or 0)+(b%0x00000080>=0x00000040~=(c%0x00000080>=0x00000040)and 0x00000040 or 0)+(b%0x00000100>=0x00000080~=(c%0x00000100>=0x00000080)and 0x00000080 or 0)+(b%0x00000200>=0x00000100~=(c%0x00000200>=0x00000100)and 0x00000100 or 0)+(b%0x00000400>=0x00000200~=(c%0x00000400>=0x00000200)and 0x00000200 or 0)+(b%0x00000800>=0x00000400~=(c%0x00000800>=0x00000400)and 0x00000400 or 0)+(b%0x00001000>=0x00000800~=(c%0x00001000>=0x00000800)and 0x00000800 or 0)+(b%0x00002000>=0x00001000~=(c%0x00002000>=0x00001000)and 0x00001000 or 0)+(b%0x00004000>=0x00002000~=(c%0x00004000>=0x00002000)and 0x00002000 or 0)+(b%0x00008000>=0x00004000~=(c%0x00008000>=0x00004000)and 0x00004000 or 0)+(b%0x00010000>=0x00008000~=(c%0x00010000>=0x00008000)and 0x00008000 or 0)+(b%0x00020000>=0x00010000~=(c%0x00020000>=0x00010000)and 0x00010000 or 0)+(b%0x00040000>=0x00020000~=(c%0x00040000>=0x00020000)and 0x00020000 or 0)+(b%0x00080000>=0x00040000~=(c%0x00080000>=0x00040000)and 0x00040000 or 0)+(b%0x00100000>=0x00080000~=(c%0x00100000>=0x00080000)and 0x00080000 or 0)+(b%0x00200000>=0x00100000~=(c%0x00200000>=0x00100000)and 0x00100000 or 0)+(b%0x00400000>=0x00200000~=(c%0x00400000>=0x00200000)and 0x00200000 or 0)+(b%0x00800000>=0x00400000~=(c%0x00800000>=0x00400000)and 0x00400000 or 0)+(b%0x01000000>=0x00800000~=(c%0x01000000>=0x00800000)and 0x00800000 or 0)+(b%0x02000000>=0x01000000~=(c%0x02000000>=0x01000000)and 0x01000000 or 0)+(b%0x04000000>=0x02000000~=(c%0x04000000>=0x02000000)and 0x02000000 or 0)+(b%0x08000000>=0x04000000~=(c%0x08000000>=0x04000000)and 0x04000000 or 0)+(b%0x10000000>=0x08000000~=(c%0x10000000>=0x08000000)and 0x08000000 or 0)+(b%0x20000000>=0x10000000~=(c%0x20000000>=0x10000000)and 0x10000000 or 0)+(b%0x40000000>=0x20000000~=(c%0x40000000>=0x20000000)and 0x20000000 or 0)+(b%0x80000000>=0x40000000~=(c%0x80000000>=0x40000000)and 0x40000000 or 0)+(b>=0x80000000~=(c>=0x80000000)and 0x80000000 or 0)return d and f(e,d,...)or e end;local function g(h)return 4294967295-h end;local function i(h,j)h=h%2^32;local k=h/2^j;return k-k%1 end;local function l(h,j)h=h%2^32;local k=h/2^j;local m=k%1;return k-m+m*2^32 end;local n={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}function str2hexa(o)local p=string.gsub(o,".",function(q)return string.format("%02x",string.byte(q))end)return p end;function num2s(r,s)local o=""for t=1,s do local u=r%256;o=string.char(u)..o;r=(r-u)/256 end;return o end;local function v(o,t)local s=0;for t=t,t+3 do s=s*256+string.byte(o,t)end;return s end;function preproc(w,x)local y=64-(x+1+8)%64;x=num2s(8*x,8)w=w.."\128"..string.rep("\0",y)..x;return w end;function initH256(z)z[1]=0x6a09e667;z[2]=0xbb67ae85;z[3]=0x3c6ef372;z[4]=0xa54ff53a;z[5]=0x510e527f;z[6]=0x9b05688c;z[7]=0x1f83d9ab;z[8]=0x5be0cd19;return z end;function digestblock(w,t,z)local A={}for B=1,16 do A[B]=v(w,t+(B-1)*4)end;for B=17,64 do local C=A[B-15]local D=f(l(C,7),l(C,18),i(C,3))C=A[B-2]local E=f(l(C,17),l(C,19),i(C,10))A[B]=A[B-16]+D+A[B-7]+E end;local F,G,q,H,I,J,K,p=z[1],z[2],z[3],z[4],z[5],z[6],z[7],z[8]for t=1,64 do local D=f(l(F,2),l(F,13),l(F,22))local L=f(a(F,G),a(F,q),a(G,q))local M=D+L;local E=f(l(I,6),l(I,11),l(I,25))local N=f(a(I,J),a(g(I),K))local O=p+E+N+n[t]+A[t]p,K,J,I,H,q,G,F=K,J,I,H+O,q,G,F,O+M end;z[1]=(z[1]+F)%2^32;z[2]=(z[2]+G)%2^32;z[3]=(z[3]+q)%2^32;z[4]=(z[4]+H)%2^32;z[5]=(z[5]+I)%2^32;z[6]=(z[6]+J)%2^32;z[7]=(z[7]+K)%2^32;z[8]=(z[8]+p)%2^32 end

    local function sha256bin(msg)
        local datauuid = component.list("data")()
        if datauuid then
            local result = {pcall(component.invoke, datauuid, "sha256", msg)}
            if result[1] and type(result[2]) == "string" then
                return result[2]
            end
        end

        msg = preproc(msg, #msg)
        local H = initH256({})
        for i = 1, #msg, 64 do digestblock(msg, i, H) end
        return num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) .. num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4)
    end

    function sha256hex(msg)
        return str2hexa(sha256bin(msg))
    end
end

local bootfs = bootloader.bootfs
local registryPath = "/data/registry.dat"

if bootfs.exists(registryPath) then
    local content = ""
    local file = bootfs.open(registryPath, "rb")
    while true do
        local data = bootfs.read(file, math.huge)
        if not data then
            break
        end
        content = content .. data
    end
    bootfs.close(file)

    local code = load("return " .. content, "=registry", "t", {})
    if code then
        local ok, registry = pcall(code)
        if ok and type(registry) == "table" and registry.password then
            while true do
                local password = recoveryApi.input("password", true)
                if not password then
                    computer.shutdown()
                end

                if sha256hex(password .. (registry.passwordSalt or "")) == registry.password then
                    break
                else
                    recoveryApi.info("invalid password")
                end
            end
        end
    end
end
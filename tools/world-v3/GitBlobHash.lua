-- Git blob SHA-1 for source identity (not authentication). UTF-8 bytes; CRLF -> LF.
local function blobHash(source)
    source = source:gsub("\r\n","\n")
    local data = "blob "..tostring(#source).."\0"..source
    local bitLength = #data*8
    assert(#data < 536870912, "Source too large")
    data = data..string.char(128)..string.rep("\0",(55-#data)%64)
        ..string.char(0,0,0,0,math.floor(bitLength/16777216)%256,
            math.floor(bitLength/65536)%256,math.floor(bitLength/256)%256,bitLength%256)
    local band,bor,bxor,bnot,rol = bit32.band,bit32.bor,bit32.bxor,bit32.bnot,bit32.lrotate
    local h0,h1,h2,h3,h4 = 0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0
    local modulus = 4294967296
    for offset = 1,#data,64 do
        local words = {}
        for i = 0,15 do
            local a,b,c,d = string.byte(data,offset+i*4,offset+i*4+3)
            words[i] = a*16777216+b*65536+c*256+d
        end
        for i = 16,79 do words[i]=rol(bxor(words[i-3],words[i-8],words[i-14],words[i-16]),1) end
        local a,b,c,d,e = h0,h1,h2,h3,h4
        for i = 0,79 do
            local f,k
            if i < 20 then f=bor(band(b,c),band(bnot(b),d)); k=0x5a827999
            elseif i < 40 then f=bxor(b,c,d); k=0x6ed9eba1
            elseif i < 60 then f=bor(band(b,c),band(b,d),band(c,d)); k=0x8f1bbcdc
            else f=bxor(b,c,d); k=0xca62c1d6 end
            local temp = (rol(a,5)+f+e+k+words[i])%modulus
            e,d,c,b,a = d,c,rol(b,30),a,temp
        end
        h0,h1,h2,h3,h4 = (h0+a)%modulus,(h1+b)%modulus,(h2+c)%modulus,(h3+d)%modulus,(h4+e)%modulus
    end
    return string.format("%08x%08x%08x%08x%08x",h0,h1,h2,h3,h4)
end
return blobHash

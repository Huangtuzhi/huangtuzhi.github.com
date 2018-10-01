---
layout: post
title: "遇到的加密算法"
description: ""
category: 
tags:
comments: yes
---

最近开发项目，遇到了各种见过没见过的算法。

## AES 算法

AES 是对称加密算法，也就是用相同的秘钥加密和解密。它有这些特点：

1、是分组加密，每个加密块大小为 128 位，即 16 个字节。

2、秘钥是 128/192/256 位。秘钥一般写为十六进制的 hex 格式，128 位秘钥就是 32 位的 hexcode。进行运算时需要将 hexcode（string 类型） 变为二进制字节流（char[16]类型）。

3、AES 有四种加密方式，常用的有 ECB 模式和 CBC 模式。

### ECB 模式

ECB 指电子密码本模式 Electronic codebook。

AES 是分组加密，以 16 个字节为一组，如果加密数据最后一个组不够 16 个字节，就需要填充为 16 个字节。这个填充方式就叫 padding。padding 方式有 zeropadding/pkcs5padding/pkcs7padding。

ECB 是最简单的 AES 算法，用秘钥分别对填充后的分组数据进行加密得到密文。所以密文和明文的长度成正比。

![](/assets/images/encrpt-algorithm-1.png)

使用 OpenSSL 库的 API 如下：

``` C++
#define COMM_AES_BLOCK_SIZE 16

int AES_ECBEncrypt(const char * sSource, const int iSize,
		const char * sKey, int iKeySize, std::string * poResult)
{
	poResult->clear();
	int padding = COMM_AES_BLOCK_SIZE - iSize % COMM_AES_BLOCK_SIZE;

	char * tmp = (char*)malloc(iSize + padding);
	memcpy(tmp, sSource, iSize);
	memset(tmp + iSize, padding, padding);
	poResult->reserve( iSize + padding);
	unsigned char key[COMM_AES_BLOCK_SIZE] = {0};
	memcpy(key, sKey, iKeySize > COMM_AES_BLOCK_SIZE ? COMM_AES_BLOCK_SIZE : iKeySize );

	AES_KEY aesKey;
	AES_set_encrypt_key(key, 8 * COMM_AES_BLOCK_SIZE, &aesKey);
	unsigned char out[ COMM_AES_BLOCK_SIZE ] = { 0 };
	for (int i = 0; i < iSize + padding; i += COMM_AES_BLOCK_SIZE) {
		AES_ecb_encrypt((unsigned char*)tmp + i, out, &aesKey, AES_ENCRYPT);
		poResult->append((char*)out, COMM_AES_BLOCK_SIZE);
	}
	free(tmp);
	return 0;
}
```

### CBC 模式

CBC 指密码分组链接模式 Cipher-block chaining。

CBC 相比 ECB 会复杂一些，它将上一次加密得到的结果与本次的数据块异或之后再进行加密。这样还需要一个初始的异或数据，叫做初始化向量 IV。

![](/assets/images/encrpt-algorithm-2.png)

```
static const int COMM_AES_BLOCK_SIZE = 16;
static const int COMM_AES_IV_SIZE = 16;
static const int COMM_AES_KEY_SIZE = 16;
static const int COMM_AES_PADDING_SIZE = 16;

int AES_CBCEncrypt( const char * sSource, const int iSize,
		const char * sKey, int iKeySize, std::string * poResult )
{

	poResult->clear();
	int padding = COMM_AES_PADDING_SIZE - iSize % COMM_AES_PADDING_SIZE;

	char * tmp = (char*)malloc( iSize + padding );
	memcpy( tmp, sSource, iSize );
	memset( tmp + iSize, padding, padding );
	
	unsigned char * out = (unsigned char*)malloc( iSize + padding );

	unsigned char key[ COMM_AES_KEY_SIZE ] = { 0 };
	unsigned char iv[ COMM_AES_IV_SIZE ] = { 0 };
	memcpy(key, sKey, COMM_AES_KEY_SIZE);
	memcpy(iv,"\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30\x30", 16); // 这里按照约定设置 

	AES_KEY aesKey;
	AES_set_encrypt_key( key, 8 * COMM_AES_BLOCK_SIZE, &aesKey );
	AES_cbc_encrypt((unsigned char *)tmp, out, iSize + padding, &aesKey, iv, AES_ENCRYPT);

	poResult->append((char*)out, iSize + padding);
	free( tmp );
	free( out );
	return 0;
}
```

## 银行通用 MAC 加密算法

银行 ATM 通信经常使用 MAC 加密算法来当签名，它们会使用加密机来生成这个签名。这次遇到的机构使用卫士通 SJL05 型金融数据加密机。而我们使用软加密的方式来模拟加密机进行加密。

### 加密机原理

加密机有两个秘钥：主秘钥和工作秘钥。我理解的加密机工作流程是这样的：用户任意输入一个工作秘钥 A，加密机对 A 使用主秘钥 B 进行 ECB 加密得到 C（PMAK），然后对 C 进行 3DES 加密得到 D。D 会作为和加密机通信的秘钥 MAK，作为通信报文字段。

因此，软加密需要用加密机主秘钥 ECB 加密工作秘钥，得到明文加密秘钥（PMAK）。即软加密 MAC 算法中输入的秘钥。

### MAC 算法

1、将需要加密的数据按照 8 个字节分组（不满 8 个字节则进行填充），然后两两异或，最终得到 8 字节的数据

2、将 8 字节的数据转换为 16 长度的 hex 十六进制数据

3、对十六进制数据进行 CBC 加密得到最终 MAC

## 参考

[AES 的工作模式](https://blog.poxiao.me/p/advanced-encryption-standard-and-block-cipher-mode/)

[SJL05金融数据加密机程序员手册](https://wenku.baidu.com/view/5260ad7602768e9951e73876.html)


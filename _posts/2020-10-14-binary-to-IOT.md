---
layout: post
title: "TecentOS Tiny-从 0/1 到 IOT 设备"
description: ""
category: 
tags:
comments: yes
---

随着网络通信技术发展，物联网在生活中应用越来越广。本文基于 TencentOS Tiny 物联网操作系统和 STM32 芯片，尝试从最底层的物理 0/1 高低电平到芯片寄存器，再到 RTOS 操作系统、甲醛传感器 IOT 组件，最后到腾讯云 IOT 平台来分析一个简单的物联网设备原理，更好的理解在嵌入式系统中软硬件是如何协作的。

---

## 一、TencentOS Tiny 架构

TencentOS tiny 主体架构图包含了这些

![](/assets/images/20201014-1.jpg)

其中 CPU/MCU 常用的 ARM Cortex 系列分为下面几类：

- Cortex-A 系列：面向性能密集型系统的应用处理器内核。应用在智能手机、上网本、数字电视等。
- Cortex-R 系列：面向实时应用的高性能内核。应用在汽车制动系统、动力传输、航天航空等。
- Cortex-M 系列：面向各类嵌入式应用的微控制器内核。应用在微控制场景、成本敏感性的产品。开发板所用的 STM32G070RBT6 就属于此类的 M0。

---

### HAL 层

SMT32 MCU 的 GPIO（General-purpose input/output）引脚连接到外围电路，MCU 通过写 GPIO 的寄存器，可以将引脚设置为输入/输出、高/低电平。这样可以感知到外界物理电路高低电平变化或控制外接电路，从而实现控制（Microcontroller）。

比如，通过写寄存器直接将 GPIOB5 口的电平设置为高电平，从而点亮 LED。

```text
GPIOB->ODR |= 1<<5; // 即 0x002333333 |= 1<<5
GPIOB->ODR &= ~(1<<5);
```

在开发中完全可以用裸的寄存器操作完成功能开发，但各种类型的芯片引脚、寄存器定义不同。如果能抽象出对 GPIO 的处理函数效率会更高，这就是 HAR（Hardware Abstract Layer）硬件抽象层。芯片厂家在[这里](https://github.com/Tencent/TencentOS-tiny/blob/cb2477f66e665b14e763746e148ff2cf4e2e82f4/platform/vendor_bsp/st/STM32WLxx_HAL_Driver/Src/stm32wlxx_hal_gpio.c#L446) HAL_GPIO_TogglePin 函数封装了对 GPIO 的处理。

---

### BSP 层

当我们尝试在 OLED 上展示 "Hello World" 时，需要频繁调用 HAL_GPIO_TogglePin。我们又可以将这些 GPIO 初始化、GPIO 电平设置的操作封装为一些函数，这样就形成了 BSP（Board Support Package）板级支持包层。TencentOS Tiny 在[这里](https://github.com/Tencent/TencentOS-tiny/blob/3fdca943d8eaafe650fa578cf8d49ef1f0b0ce95/board/TencentOS_tiny_EVB_MX_Plus/BSP/Hardware/OLED/oled.h#L29) OLED_ShowString 函数封装了液晶屏展示的功能。

板级支持包也可以看做显示屏/传感器/串口模块/WIFI 模块支持包，上层应用不需要关心底层的寄存器操作和电平变化。通过由下而上的 HAL 层、BSP 层，TencentOS tiny 将最下层的硬件层屏蔽起来，可以在此之上构建操作系统 Kernel。

---

### 操作系统抽象层

TencentOS tiny 实时内核包括任务管理、实时调度、时间管理、中断管理、内存管理、异常处理、软件定时器、链表、消息队列、信号量、互斥锁、事件标志等模块，实现了一个操作系统所有的机制。

为了形成完整的物联网组件 + 物联网操作系统 + 腾讯云 IOT 平台，定制化操作系统抽象层有很多优势。通过向下封装基础物联网组件 BSP，向上封装腾讯云 IOT 能力，如果形成行业统一的标准，会很大程度提升产品研发效率。

---

## 二、甲醛监测仪搭建步骤

主要需要把 TOS EVB G0 [开发板](http://www.holdiot.com/product/showproduct.php?id=8)、ESP8266 WIFI 模块、甲醛传感器搭建成甲醛监测仪，步骤如下：

1、通过串口下载固件到 ESP8266 WIFI 模块

ESP8266 模块本身也有 Tensilica L106 控制芯片，可以进行编程实现功能。TencentOS Tiny 已经提供了和腾讯云 IOT 平台对接的[代码](https://github.com/tencentyun/qcloud-iot-esp-wifi/tree/master/qcloud-iot-esp8266-demo)编译出来的 bin 二进制（固件），只需要将二进制烧录到芯片中就可以实现和腾讯云 IOT 的交互。TencentOS Tiny 做的工作是扩展封装了 ESP8266 的 AT 指令集，这样 STM32 芯片只需要通过串口把 [AT 指令](https://github.com/Tencent/TencentOS-tiny/blob/757c46f9ff74140e842ae977aabd6fe4f6fc9e30/devices/esp8266_tencent_firmware/esp8266_tencent_firmware.c#L162)发送到 ESP8266 上，就能实现 STM32 和腾讯云 IOT 平台的通信。

![](/assets/images/20201014-2.jpg)

在下载 bin 二进制时，需要把ESP_TXD 连接 USB 转串口芯片引脚 CH340_RX，ESP_RXD 连接 CH340_TX。这样 ESP8266 直接连接到 PC 串口 COM*，可以直接下载 bin 二进制。下载完后，恢复连接 1-3、5-7、2-4、6-8，让 ESP8266 和 STM32 相连，这样 STM32 才能控制 ESP8266 WIFI 模块。

![](/assets/images/20201014-3.jpg)

2、通过 ST-LINK 下载程序到 STM32G070RBT6 芯片

使用 ST-LINK 调试器串行调试 SWD（Serial Wire Debug）模式来下载程序到芯片中。SWD 是芯片自身支持的调试能力。

---

## 三、代码分析

要理解整个嵌入式系统的原理，还需要分析一下工程的代码。整个工程路径在[这里](https://github.com/Tencent/TencentOS-tiny/blob/master/board/TencentOS_tiny_EVB_G0/KEIL/mqtt_iot_explorer_tc_ch20_oled/demo/mqtt_iot_explorer_tc_ch20_oled.c)。

---

### 应用入口

整个工程的入口函数是 application_entry，它对应的[定义](https://github.com/Tencent/TencentOS-tiny/blob/master/arch/arc/common/tos_embarc.c)是：

```
extern void application_entry(void *arg);
osThreadDef(application_entry, osPriorityNormal, 
                       1, APPLICATION_TASK_STK_SIZE);
EMBARC_WEAK void application_entry(void *arg)
{
    while (1) {
        printf("This is a demo task!\r\n");
        tos_task_delay(1000);
    }
}

int main(void)
{
    /* OS kernel initialization */
    osKernelInitialize();
    /* application initialization entry */
    osThreadCreate(osThread(application_entry), NULL);
    /* start kernel */
    osKernelStart();
}
```

osThreadDef 将 application_entry 函数定义成一个 os_thread_def 线程结构体，osKernelInitialize 用来初始化内核，接着 osThreadCreate 创建 application_entry 为主体函数的线程。osKernelStart 启动 RTOS 内核。整个 RTOS 使用参考 [CMSIS-RTOS API](https://github.com/Tencent/TencentOS-tiny/blob/d3b495a59805561a2e14b49e1ab21d196b9d4567/doc/23.CMSIS_RTOS_API_Use_Guide.md)。

---

### 主任务线程

OLED 显示、读取甲醛传感器数值、WIFI 通信的主要逻辑写在 mqtt_demo_task 中。

```
// 初始化 WIFI 模块连接的 UART2 串口
esp8266_tencent_firmware_sal_init(HAL_UART_PORT_2); 
// 加入 WIFI 网络
esp8266_tencent_firmware_join_ap("user", "passwd"); 
```

UART3 连接了甲醛传感器读取数值，当需要读取数值时需要使用 HAL_NVIC_EnableIRQ 打开 UART3 的中断 ，让 CPU 能接收中断。

UART 引脚连接的功能如下：

- UART1：USB 转串口芯片 CH340 引脚 
- UART2：ESP8266 WIFI 模块引脚
- UART3：E53 甲醛传感器底板引脚
- UART4：P6 4 针插线柱

核心逻辑主要有下列几步：

1、读取甲醛传感器数据

读取甲醛传感器数据由 ch20_parser.c 中的 ch20_parser_task_entry 线程处理，读取完成后通过 tos_mail_q_post 发送到邮箱，主线程通过 tos_mail_q_pend 读取邮箱数据。

那么 ch20_parser_task_entry 线程中的数据来源于哪里呢？是在 [stm32g0xx_it_demo.c](https://github.com/Tencent/TencentOS-tiny/blob/4ab6c63046bf71aed4b16aaa57c16aa99a8e4ea8/board/TencentOS_tiny_EVB_G0/KEIL/mqtt_iot_explorer_tc_ch20_oled/demo/stm32g0xx_it_demo.c#L209) 中 HAL_UART_RxCpltCallback 接收 CPU 的 UART3 中断回调时写入的。

2、通过 WIFI 上传数据到腾讯云 IOT

上传数据是通过 tos_tf_module_mqtt_pub 发送数据到队列，其实是把 AT  指令 + 数据写到 UART2 的 WIFI 模块，WIFI 模块再上传数据。

```
int esp8266_tencent_firmware_module_mqtt_pub(const char *topic, qos_t qos,
 char *payload)
{
    at_echo_t echo;

    tos_at_echo_create(&echo, NULL, 0, "+TCMQTTPUB:OK");

    tos_at_cmd_exec(&echo, 1000, "AT+TCMQTTPUB=\"%s\",%d,\"%s\"\r\n", 
            topic, qos, payload);
    if (echo.status == AT_ECHO_STATUS_OK || 
         echo.status == AT_ECHO_STATUS_EXPECT)  {
        return 0;
    }
    return -1;
}
```

---

## 四、从 0/1 到 IOT 设备

![](/assets/images/20201014-4.jpg)

![](/assets/images/20201014-5.jpg)

这样就完成了从硬件层 0/1 高低电平到 STM32 芯片，再到 RTOS 操作系统、甲醛传感器物联网组件，最后到腾讯云 IOT 平台的整个流程。

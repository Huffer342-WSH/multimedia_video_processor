//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           eth_ctrl
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        ��̫������ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module eth_ctrl (
    input            clk,               //ʱ��
    input            resetn,             //ϵͳ��λ�źţ��͵�ƽ��Ч 
    //ARP��ض˿��ź�                                   
    input            arp_rx_done,       //ARP��������ź�
    input            arp_rx_type,       //ARP�������� 0:����  1:Ӧ��
    output reg       arp_tx_en,         //ARP����ʹ���ź�
    output           arp_tx_type,       //ARP�������� 0:����  1:Ӧ��
    input            arp_tx_done,       //ARP��������ź�
    input            arp_gmii_tx_en,    //ARP GMII���������Ч�ź� 
    input      [7:0] arp_gmii_txd,      //ARP GMII�������
    //ICMP��ض˿��ź�
    input            icmp_tx_start_en,  //ICMP��ʼ�����ź�
    input            icmp_tx_done,      //ICMP��������ź�
    input            icmp_gmii_tx_en,   //ICMP GMII���������Ч�ź�  
    input      [7:0] icmp_gmii_txd,     //ICMP GMII������� 
    //ICMP fifo�ӿ��ź�
    input            icmp_rec_en,       //ICMP���յ�����ʹ���ź�
    input      [7:0] icmp_rec_data,     //ICMP���յ�����
    input            icmp_tx_req,       //ICMP�����������ź�
    output     [7:0] icmp_tx_data,      //ICMP����������
    //UDP��ض˿��ź�
    input            udp_tx_start_en,   //UDP��ʼ�����ź�
    input            udp_tx_done,       //UDP��������ź�
    input            udp_gmii_tx_en,    //UDP GMII���������Ч�ź�  
    input      [7:0] udp_gmii_txd,      //UDP GMII�������   
    //UDP fifo�ӿ��ź�
    // input      [7:0] udp_rec_data,      //UDP���յ�����
    // input            udp_rec_en,        //UDP���յ�����ʹ���ź� 
    // input            udp_tx_req,        //UDP�����������ź�
    // output     [7:0] udp_tx_data,       //UDP����������
    //fifo�ӿ��ź�
    input      [7:0] tx_data,           //�����͵�����
    output           tx_req,            //�����������ź� 
    output reg       rec_en,            //���յ�����ʹ���ź�
    output reg [7:0] rec_data,          //���յ�����
    //GMII��������                  	   
    output reg       gmii_txd_valid,        //GMII���������Ч�ź� 
    output reg [7:0] gmii_txd_data           //GMII������� 
);

  //reg define
  reg [1:0] protocol_sw;  //Э���л��ź�
  reg       icmp_tx_busy;  //ICMP���ڷ������ݱ�־�ź�	
  reg       udp_tx_busy;  //UDP���ڷ������ݱ�־�ź�
  reg       arp_rx_flag;  //���յ�ARP�����źŵı�־
  reg       icmp_tx_req_d0;  //ICMP�����������źżĴ���
  reg       udp_tx_req_d0;  //UDP�����������źżĴ���

  //*****************************************************
  //**                    main code
  //*****************************************************

  assign arp_tx_type  = 1'b1;  //ARP�������͹̶�ΪARPӦ��    				
  // assign tx_req       = udp_tx_req ? 1'b1 : icmp_tx_req;  //�����������ź�ѡ��
  assign tx_req       = icmp_tx_req;  //�����������ź�ѡ��

  assign icmp_tx_data = icmp_tx_req_d0 ? tx_data : 8'd0;  //ICMP����������ѡ��
  // assign udp_tx_data  = udp_tx_req_d0 ? tx_data : 8'd0;  //UDP����������ѡ��

  //ICMP�����������źź�UDP�����������źżĴ�һ��
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      icmp_tx_req_d0 <= 1'd0;
      // udp_tx_req_d0  <= 1'd0;
    end else begin
      icmp_tx_req_d0 <= icmp_tx_req;
      // udp_tx_req_d0  <= udp_tx_req;
    end
  end

  //��������ʹ���ź���������ݵ��ж�
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      rec_en   <= 1'd0;
      rec_data <= 1'd0;
    end else if (icmp_rec_en) begin
      rec_en   <= icmp_rec_en;
      rec_data <= icmp_rec_data;
    end 
    // else if (udp_rec_en) begin
      // rec_en   <= udp_rec_en;
      // rec_data <= udp_rec_data;
    // end 
    else begin
      rec_en   <= 1'd0;
      rec_data <= rec_data;
    end
  end

  //Э����л�
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      gmii_txd_valid <= 1'd0;
      gmii_txd_data   <= 8'd0;
    end else begin
      case (protocol_sw)
        2'b00: begin
          gmii_txd_valid <= arp_gmii_tx_en;
          gmii_txd_data   <= arp_gmii_txd;
        end
        2'b01: begin
          gmii_txd_valid <= udp_gmii_tx_en;
          gmii_txd_data   <= udp_gmii_txd;
        end
        2'b10: begin
          gmii_txd_valid <= icmp_gmii_tx_en;
          gmii_txd_data   <= icmp_gmii_txd;
        end
        default: ;
      endcase
    end
  end

  //����ICMP����æ�ź�
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      icmp_tx_busy <= 1'b0;
    end else if (icmp_tx_start_en) icmp_tx_busy <= 1'b1;
    else if (icmp_tx_done) icmp_tx_busy <= 1'b0;
    else;
  end


  //����UDP����æ�ź�
  always @(posedge clk or negedge resetn) begin
    if (!resetn) udp_tx_busy <= 1'b0;
    else if (udp_tx_start_en) udp_tx_busy <= 1'b1;
    else if (udp_tx_done) udp_tx_busy <= 1'b0;
    else;
  end

  //���ƽ��յ�ARP�����źŵı�־
  always @(posedge clk or negedge resetn) begin
    if (!resetn) arp_rx_flag <= 1'b0;
    else if (arp_rx_done && (arp_rx_type == 1'b0)) arp_rx_flag <= 1'b1;
    else arp_rx_flag <= 1'b0;
  end

  //����protocol_sw��arp_tx_en�ź�
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      protocol_sw <= 2'b0;
      arp_tx_en   <= 1'b0;
    end else begin
      arp_tx_en <= 1'b0;
      if (icmp_tx_start_en) begin
        protocol_sw <= 2'b10;
      end else if (udp_tx_start_en) begin
        protocol_sw <= 2'b01;
      end  else if ((arp_rx_flag && (udp_tx_busy == 1'b0)) || (arp_rx_flag && (icmp_tx_busy == 1'b0))) begin
        protocol_sw <= 2'b0;
        arp_tx_en   <= 1'b1;
      end else;
    end
  end

endmodule

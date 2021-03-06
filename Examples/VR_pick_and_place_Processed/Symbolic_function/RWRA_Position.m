function out1 = RWRA_Position(in1,in2,in3)
%RWRA_POSITION
%    OUT1 = RWRA_POSITION(IN1,IN2,IN3)

%    This function was generated by the Symbolic Math Toolbox version 8.1.
%    25-Oct-2018 19:16:00

R3cut1_1 = in3(19);
R3cut1_2 = in3(22);
R3cut1_3 = in3(25);
R3cut2_1 = in3(20);
R3cut2_2 = in3(23);
R3cut2_3 = in3(26);
R3cut3_1 = in3(21);
R3cut3_2 = in3(24);
R3cut3_3 = in3(27);
p3cut1 = in2(7);
p3cut2 = in2(8);
p3cut3 = in2(9);
q19 = in1(19,:);
q20 = in1(20,:);
q21 = in1(21,:);
t2 = cos(q19);
t3 = sin(q19);
t4 = sin(q20);
t5 = cos(q20);
t6 = R3cut1_1.*t2;
t7 = t6-R3cut1_3.*t3;
t8 = cos(q21);
t9 = sin(q21);
t10 = R3cut2_1.*t2;
t11 = t10-R3cut2_3.*t3;
t12 = R3cut3_1.*t2;
t13 = t12-R3cut3_3.*t3;
out1 = [R3cut1_2.*(-3.134949875058856e-1)+p3cut1-R3cut1_2.*t5.*2.69331427615625e-1+t4.*t7.*2.69331427615625e-1+t8.*(R3cut1_1.*t3+R3cut1_3.*t2).*4.784570142690599e-2+t9.*(R3cut1_2.*t4+t5.*t7).*4.784570142690599e-2;R3cut2_2.*(-3.134949875058856e-1)+p3cut2-R3cut2_2.*t5.*2.69331427615625e-1+t4.*t11.*2.69331427615625e-1+t8.*(R3cut2_1.*t3+R3cut2_3.*t2).*4.784570142690599e-2+t9.*(R3cut2_2.*t4+t5.*t11).*4.784570142690599e-2;R3cut3_2.*(-3.134949875058856e-1)+p3cut3-R3cut3_2.*t5.*2.69331427615625e-1+t4.*t13.*2.69331427615625e-1+t8.*(R3cut3_1.*t3+R3cut3_3.*t2).*4.784570142690599e-2+t9.*(R3cut3_2.*t4+t5.*t13).*4.784570142690599e-2];

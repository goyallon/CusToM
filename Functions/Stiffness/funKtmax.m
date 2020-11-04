function fvalKt=funKtmax(A,i,BiomechanicalModel,MuscleConcerned,SolidConcerned,q,Fext,Fa,Fp,effector)
FMT=Fa(:,i).*A(1:Nb_muscles,i)+Fp(:,i);
Kt=TaskStiffness(BiomechanicalModel,MuscleConcerned,SolidConcerned,q(:,i),Fext,FMT,effector);
[V,D] = eig(Kt);
funKtmax=norm(sum(V.*diag(D)));
end
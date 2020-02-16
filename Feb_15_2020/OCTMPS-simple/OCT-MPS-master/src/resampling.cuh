#ifndef _GPU_resampling_H_
#define _GPU_resampling_H_


#include "octmps_kernel.h"
#include "octmps.h"




#include <cstdlib>
#include <cstdio>
using namespace std;



__global__ void random_setup(curandState *states,long seed)
{
    int tid = threadIdx.x + blockIdx.x*blockDim.x;

    //curand_init(seed,tid,0,&states[tid]);		//slow version


    curand_init((seed+tid)*10,0,0,&states[tid]);	//fast version, not not accurate?
}



__global__ void GPU_rejection_v3(int *sample, int *new_sample, FLOAT *sample_w, int num_sample,curandState *states){

	//thread id
	const int tid = threadIdx.x + blockIdx.x*blockDim.x;
    curandState *state = states + tid;
    int flag = 0;

    while(1){
    	if(flag ==1){
    		break;
    	}
	    FLOAT rand = curand_uniform(state);
	    int rand_int = ceilf(curand_uniform(state) * num_sample);

		FLOAT check = sample_w[rand_int] / 1;	//we set 1 is the max weight in our case

		if (rand <= check){
			new_sample[tid] = sample[rand_int];
			flag = 1;
		}else{
			rand = curand_uniform(state);
			rand_int = ceilf(curand_uniform(state) * num_sample);
		}

    }

}



__global__ void GPU_metropolis_v3(int *sample, int *new_sample, FLOAT *sample_w, int num_sample,int B_value,curandState *states){

	//thread id
	const int tid = threadIdx.x + blockIdx.x*blockDim.x;
    curandState *state = states + tid;

	for(int i =0; i <B_value; i++){
	    FLOAT rand = curand_uniform(state);
	    int rand_int = ceilf(curand_uniform(state) * num_sample);
		FLOAT check = expf(logf(sample_w[rand_int])-logf(sample_w[tid]));
		if(rand <= check){
			new_sample[tid] = sample[rand_int];
		}
		else{
			new_sample[tid] = sample[tid];
		}

	}

}








__device__ void swap_photon_input(GPUThreadStates* tstates,
		PhotonStructGPU* photon,
		UINT32 tid,int *new_sample) {

	/************
	 *  Photon
	 ***********/

	photon->x = tstates->photon_x[new_sample[tid]];
	photon->y = tstates->photon_y[new_sample[tid]];
	photon->z = tstates->photon_z[new_sample[tid]];

	photon->ux = tstates->photon_ux[new_sample[tid]];
	photon->uy = tstates->photon_uy[new_sample[tid]];
	photon->uz = tstates->photon_uz[new_sample[tid]];

	//photon->w = tstates->photon_w[new_sample[tid]];			//dont need to swap weight
	photon->dead = tstates->dead[new_sample[tid]];
	photon->hit = tstates->hit[new_sample[tid]];

	photon->MinCos = tstates->MinCos[tid];

	photon->rootIdx = tstates->rootIdx[new_sample[tid]];
	photon->NextTetrahedron = tstates->NextTetrahedron[new_sample[tid]];

	photon->tetrahedron = tstates->tetrahedron;
	photon->faces = tstates->faces;

	photon->s = tstates->photon_s[new_sample[tid]];
	photon->sleft = tstates->photon_sleft[new_sample[tid]];
	photon->OpticalPath = tstates->OpticalPath[new_sample[tid]];
	photon->MaxDepth = tstates->MaxDepth[new_sample[tid]];
	photon->LikelihoodRatio = tstates->LikelihoodRatio[new_sample[tid]];

	photon->LikelihoodRatioAfterFstBias =
				tstates->LikelihoodRatioAfterFstBias[new_sample[tid]];

	photon->FstBackReflectionFlag = tstates->FstBackReflectionFlag[new_sample[tid]];
	photon->LocationFstBias = tstates->LocationFstBias[new_sample[tid]];

	photon->NumBackwardsSpecularReflections =
				tstates->NumBackwardsSpecularReflections[new_sample[tid]];


	//photon->is_active = tstates->is_active[new_sample[tid]]				//fix this

}



__device__ void swap_photon_output(GPUThreadStates* tstates,
		PhotonStructGPU* photon,
		UINT32 tid) {

	/************
	 *  Photon
	 ***********/

	tstates->photon_x[tid]	=	photon->x;
	tstates->photon_y[tid]	=	photon->y;
	tstates->photon_z[tid]	=	photon->z;

	tstates->photon_ux[tid]	=	photon->ux;
	tstates->photon_uy[tid]	=	photon->uy;
	tstates->photon_uz[tid]	=	photon->uz;

	tstates->photon_w[tid]	=	1.0;					//set weight to 1.0 after resampling
	tstates->dead[tid]	=	photon->dead;
	tstates->hit[tid]	=	photon->hit;

	tstates->MinCos[tid]	=	photon->MinCos;

	tstates->rootIdx[tid]	=	photon->rootIdx;
	tstates->NextTetrahedron[tid]	=	photon->NextTetrahedron;

	tstates->tetrahedron	=	photon->tetrahedron;
	tstates->faces	=	photon->faces;

	tstates->photon_s[tid]	=	photon->s;
	tstates->photon_sleft[tid]	=	photon->sleft;
	tstates->OpticalPath[tid]	=	photon->OpticalPath;
	tstates->MaxDepth[tid]	=	photon->MaxDepth;
	tstates->LikelihoodRatio[tid]	=	photon->LikelihoodRatio;

	tstates->LikelihoodRatioAfterFstBias[tid]	=	photon->LikelihoodRatioAfterFstBias;

	tstates->FstBackReflectionFlag[tid]	=	photon->FstBackReflectionFlag;
	tstates->LocationFstBias[tid]	=	photon->LocationFstBias;

	tstates->NumBackwardsSpecularReflections[tid]	=	photon->NumBackwardsSpecularReflections;





	//tstates->FstBackReflectionFlag[tid] = 0;
	tstates->is_active[tid] = 1;							//is_active = 1

}









__global__ void Resampling_Swap_v2(SimState* d_state, GPUThreadStates *tstates ,int *new_sample){

	//thread id
	const int tid = threadIdx.x + blockIdx.x*blockDim.x;

	PhotonStructGPU photon;


	/*
	 * Input
	 *
	 */
	/*
	if(tid == 0){

		printf("in GPU	%d	and	%d,%d,%d\n",new_sample[tid],d_state->x[new_sample[tid]],d_state->xR[new_sample[tid]],d_state->xS[new_sample[tid]]);

	}
	*/




	UINT64 	swap_x	=	d_state->x[new_sample[tid]];
	UINT32	swap_a	=	d_state->a[new_sample[tid]];
	UINT64	swap_xR	=	d_state->xR[new_sample[tid]];
	UINT32	swap_aR	=	d_state->aR[new_sample[tid]];
	UINT64	swap_xS	=	d_state->xS[new_sample[tid]];
	UINT32	swap_aS	=	d_state->aS[new_sample[tid]];



	swap_photon_input(tstates, &photon, tid, new_sample);

	/*
	 * Output
	 *
	 */
	d_state->x[tid]	=	swap_x;
	d_state->a[tid]	=	swap_a;
	d_state->xR[tid]	=	swap_xR;
	d_state->aR[tid]	=	swap_aR;
	d_state->xS[tid]	=	swap_xS;
	d_state->aS[tid]	=	swap_aS;


	swap_photon_output(tstates, &photon, tid);



}





/*
__global__ void OCTMPSKernel_Secondary(SimState* d_state, GPUThreadStates* tstates) {
	// photon structure stored in registers
	PhotonStructGPU photon;							//primary photon 	(JUNYAO)
	PhotonStructGPU photon_cont;					//secondary photon	(JUNYAO)

	// random number seeds
	UINT64 rnd_x, rnd_xR, rnd_xS;
	UINT32 rnd_a, rnd_aR, rnd_aS;

	// probe locations
	FLOAT probe_x, probe_y, probe_z;

	// Flag to indicate if this thread is active
	UINT32 is_active;



	UINT32 tid = blockIdx.x * blockDim.x + threadIdx.x;


	// Restore the thread state from global memory								//transfer from global to register for speed up? (JUNYAO)
	RestoreThreadState(d_state, tstates, &photon, &photon_cont, &rnd_x, &rnd_a,
			&rnd_xR, &rnd_aR, &rnd_xS, &rnd_aS, &is_active, &probe_x, &probe_y, &probe_z);








	if (photon.FstBackReflectionFlag && d_simparam.TypeBias != 3) {

		//secondary photon packet (JUNYAO)
		FLOAT LikelihoodRatioTmp = photon.LikelihoodRatioAfterFstBias;


		CopyPhotonStruct(&photon_cont, &photon);



		Spin(d_regionspecs[photon.tetrahedron[photon.rootIdx].region].g, &photon, &rnd_xS, &rnd_aS);

		if (LikelihoodRatioTmp < 1)
			photon.LikelihoodRatio = 1 - LikelihoodRatioTmp;
		else
			photon.LikelihoodRatio = 1;
	}else{

		is_active = 0;

	}



	//reset saved photon packet, so they can have new secondary photon packet after resampling

	tstates->FstBackReflectionFlag[tid] = 0;







	//stop until the secondary photon packet dead
	if (is_active) {

		while(1){

			ComputeStepSize(&photon, &rnd_x, &rnd_a);

			photon.hit = HitBoundary(&photon);

			Hop(&photon);

			if (photon.hit)
				FastReflectTransmit(&photon, d_state, &rnd_xR, &rnd_aR, probe_x, probe_y, probe_z);
			else {
				Drop(&photon);
				switch (d_simparam.TypeBias) {
				case 0:
					Spin(d_regionspecs[photon.tetrahedron[photon.rootIdx].region].g, &photon, &rnd_xS, &rnd_aS);
					break;
				case 37:
					SpinBias(d_regionspecs[photon.tetrahedron[photon.rootIdx].region].g, photon.tetrahedron[photon.rootIdx].region, &photon, &photon_cont, &rnd_xS, &rnd_aS, probe_x, probe_y, probe_z);
					break;
				}
			}


			 //*  Roulette()
			 //*  If the photon weight is small, the photon packet tries
			 //*  to survive a roulette

			if (photon.w < WEIGHT) {
				FLOAT rand = rand_MWC_co(&rnd_x, &rnd_a);

				if (photon.w != ZERO_FP && rand < CHANCE) {

					//photon packet survive (JUNYAO)		w = m*w
					photon.w *= (FLOAT) FAST_DIV(FP_ONE, CHANCE);
				}else{

					break;
				}
			}

		}

	}


}
*/










/*
 * variance calculation
 *
 *
 */

FLOAT mean(FLOAT values[], int n)

{

    FLOAT sum = 0;

    for (int i = 0; i < n; i++)

    {

        sum += values[i];

    }

    return sum / n;

}



FLOAT var(FLOAT values[], int n)

{

    FLOAT valuesMean = mean(values, n);

    FLOAT sum = 0;

    for (int i = 0; i < n; i++)

    {

        sum += (values[i] - valuesMean) * (values[i] - valuesMean);

    }

    return sum / (n-1);

}







#endif

import numpy as np
import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib import pyplot as plt
import csv
from itertools import cycle
cycol = cycle('bgrcmk')

__author__ = 'Siavash Malektaji'
__license__ = "GPL"
__email__ = "siavashmalektaji@gmail.com"

font = {'family': 'serif',
        'weight': 'normal',
        'size': 24}

plt.rc('font', **font)

def forceAspect(ax,aspect=1):
    im = ax.get_images()
    extent =  im[0].get_extent()
    ax.set_aspect(abs((extent[1]-extent[0])/(extent[3]-extent[2]))/aspect)


def parse_OCTMPS_output_files(*files_labels):
    show_variance=True

    def parse_row(file_name):
        with open(file_name, 'r') as f:
            reader = csv.reader(f)
            for row in reader:
                parsed_row = list(map(lambda x: float(x) , row))
                yield parsed_row

    for label, file_name in files_labels:

        classI_z_positions = np.array(list(sorted(set([x[1] for x in parse_row(file_name)]))))
        classI_reflectances = np.array([x[2] for x in parse_row(file_name)])
        classI_variances = np.array([x[3] for x in parse_row(file_name)])
        plt.semilogy(classI_z_positions, classI_reflectances, next(cycol), label=label)
        '''
        if show_variance:
            plt.errorbar(classI_z_positions, classI_reflectances, yerr=classI_variances)
        '''


        sub_classI_z_positions  = []
        sub_classI_reflectances     = []
        sub_classI_variances        = []


        for i in range(len(classI_z_positions)):
            if i%5 == 0:
                sub_classI_z_positions.append(classI_z_positions[i])
                sub_classI_reflectances.append(classI_reflectances[i])
                sub_classI_variances.append(classI_variances[i])

        '''
        if show_variance:
            plt.errorbar(sub_classI_z_positions, sub_classI_reflectances, yerr=sub_classI_variances, color='red', fmt='.', markersize='1', ecolor='black',capsize=6, elinewidth=2)
        '''

    plt.xlabel('Depth [cm]', **font)
    plt.xlim(0, 0.11)
    plt.ylabel('Reflectance', **font)
    plt.legend(loc='upper right', shadow=True, fontsize=10)
    plt.axes().set_aspect('auto')
    plt.grid(True)
    plt.title('Class I signal for sphere sample without error bar')

    plt.show()

if __name__ == '__main__':

    # Fig 6. A-scans representing Class I reflectance-based OCT signals from the  above simulation obtained by OCT-MPS
    # and by the serial implementation [9].
    # parse_OCTMPS_output_files(('Class I signal from serial implementation [9]',
    #                           '../../output/journal_paper_validation/serial_code/ClassI_ScattFilt.out'),
    #                          ('Class I signal from OCT-MPS',
    #                           '../../output/journal_paper_validation/parallel_code/ClassI_ScattFilt.out'))

    # Fig 7. A-scans representing Class II reflectance-based OCT signals from the above simulation obtained by OCT-MPS
    # and from the serial implementation [9].
    # parse_OCTMPS_output_files(('Class II signal from serial implementation [9]',
    #                           '../../output/journal_paper_validation/serial_code/ClassII_ScattFilt.out'),
    #                           ('Class II signal from OCT-MPS',
    #                           '../../output/journal_paper_validation/parallel_code/ClassII_ScattFilt.out'))

    # Fig 8. Class I OCT signals and their confidence intervals using 10^7, 10^6, and 10^5 photon packets.

    '''
    parse_OCTMPS_output_files((r' ',
                               '/home/junyao/Desktop/One_Plot/ClassI_ScattFilt.out'),
                              )

    '''


    parse_OCTMPS_output_files(('Metropolis_16_Step_30720',
                                '/home/junyao/Desktop/One_Plot/Metropolis_16_Step_30720.out'),
                                ('Metropolis_8_Step_30720',
                                '/home/junyao/Desktop/One_Plot/Metropolis_8_Step_30720.out'),
                                ('Rejection_30720',
                                '/home/junyao/Desktop/One_Plot/Rejection.out'),
                                ('No_Resampling_30720',
                                '/home/junyao/Desktop/One_Plot/No_Resampling_30720.out'),
                                ('No_Resampling_10^7',
                                '/home/junyao/Desktop/One_Plot/No_Resampling.out'))

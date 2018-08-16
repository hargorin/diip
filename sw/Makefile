
APPS =	clahe/clahe 						\
		diip_cc/bin/diip_cc 					\
		diip_cc_hls/bin/diip_cc 				\
		file2image/file2image 				\
		image2file/image2file  				\
		uft/sender 						\
		uft/receiver 						\
		wallis_filter/wallis_filter				\
		wallis_filter_datatxt_out/wallis_filter

all: $(APPS)

$(APPS):
	cd $(dir $@) && $(MAKE)

clean: 
	rm $(APPS)




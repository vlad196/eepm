#!/bin/sh

[ "$1" != "--run" ] && echo "Switch to using open source driver nouveau for NVIDIA cards" && exit

. $(dirname $0)/common.sh

assure_root
exit

[ "$(epm print info -s)" = "alt" ] || fatal "Only ALTLinux is supported"

# https://www.altlinux.org/Nvidia#Смена_открытых_драйверов_на_проприетарные[1]

epm update || fatal
epm update-kernel || fatal

# проверяем, совпадает ли ядро (пока нет такой проверки в update-kernel)
USED_KFLAVOUR="$(uname -r | awk -F'-' '{print $(NF-2)}')-def"
check_run_kernel () {
    # TODO: support kernel-image-rt
    ls /boot | grep "vmlinuz" | grep -vE 'vmlinuz-un-def|vmlinuz-std-def' | grep "${USED_KFLAVOUR}" | sort -Vr | head -n1 | grep -q $(uname -r)
}

#TODO: добавить удаление драйверов nvidia. Возможно через скрипт

if check_run_kernel ; then
	echo "Запущено самое свежее установленное ${USED_KFLAVOUR} ядро."
else
	echo "В системе есть ${USED_KFLAVOUR} ядро свежее запущенного."
	echo "Перезагрузитесь со свежим ${USED_KFLAVOUR} ядром и перезапустите: epm play switch-to-nvidia"
	fatal
fi

Устанавливаем kernel-modules-drm-nouveau-std-def(un-def) xorg-drv-nouveau и xorg-dri-nouveau
epm install --skip-installed xorg-drv-nouveau xorg-dri-nouveau-${USED_KFLAVOUR}  || fatal

# Проверяем, существует ли файлы файлы конфигурации, установленные для nvidia драйверов
/etc/modprobe.d/blacklist-nvidia-x11.conf и /etc/modprobe.d/blacklist-alterator-x11.conf. Если есть, то удаляем.
if [ -f "/etc/modprobe.d/blacklist-nvidia-x11.conf" ]; then
  rm -f /etc/modprobe.d/blacklist-nvidia-x11.conf
fi
if [ -f "/etc/modprobe.d/blacklist-alterator-x11" ]; then
  rm -f /etc/modprobe.dblacklist-alterator-x11.conf
fi
if [ -f "/etc/modprobe.d/nvidia_videomemory_allocation.conf" ]; then
  rm -f /etc/modprobe.d/nvidia_videomemory_allocation.conf
fi
# Проверяем, все файлы конфигурации, и удаление строк с "blacklist nouveau" и "options nvidia"
for filename in "/etc/modprobe.d/*; do
    if [ -f "$filename" ]; then
        # Проверяем, есть ли строки "blacklist nouveau" или "options nvidia" в файле
        if grep -qE "blacklist nouveau|options nvidia" "$filename"; then
            # Удаляем строки из файла
            sed -i '/blacklist nouveau\|options nvidia/d' "$filename"
        fi
    fi
done

# Удаляем фикс "неизвестный монитор", если он существует
if grep "initcall_blacklist=simpledrm_platform_driver_init" /etc/sysconfig/grub2 &>/dev/null ; then 
	echo "Создание копии /etc/sysconfig/grub2..."
	cp /etc/sysconfig/grub2 /etc/sysconfig/grub2.epmbak
  sed -i 's/initcall_blacklist=simpledrm_platform_driver_init//' /etc/sysconfig/grub2
fi

a= x11presetdrv # сканирует PCI в /sys на предмет видеоплат производителя NVIDIA. Если таковые найдены, ищет пары драйверов ядерный+X-овый, совпадающие по версии. Переключает /lib/modules/`uname -r`/nVidia/nvidia.ko на выбранную версию
a= ldconfig # обновляет кэш информации о новейших версиях разделяемых библиотек

echo "Запускаем регенерацию initrd."
make-initrd

echo "Обновляем grub..."
update-grub

echo "Выполнено. Перезагрузите систему для использования проприетарных драйверов nvidia."
